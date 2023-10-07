# Solution to Advent of Code 2021, Day 19
# https://adventofcode.com/2021/day/19

Code.require_file("Util.ex", "..")

# returns a list of text blocks from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n\n", trim: true)
end

parse_block = fn block ->
  String.split(block, "\n", trim: true) |> tl |>  # drop header line
  Enum.map(&Util.read_numbers/1)
end

data = read_input.() |> Enum.map(parse_block) |> Enum.with_index

# Since all location data is relative, the only way to uniquely identify
# beacons is by their distances relative to each other. Create a map
# of each beacon's distance from each other beacon (or rather the square
# of the distance, extending the Pythagorean theorem to three dimensions).
calc_d = fn i, j -> Integer.pow(i - j, 2) end

# Once we have the distance data, we can fingerprint each point based on
# a sorted list of its distances to all the other points in its system.
# Counting these will also tell us how many total beacons there are.
info =
  Enum.reduce(data, {%{}, %{}, MapSet.new}, fn {s, n}, {dist, unique, ct} ->
    limit = length(s) - 1
    {dist_n, uniq_n} =
      # counting $j up from $i to avoid counting the same distance twice
      for i <- 0..limit, j <- (i + 1)..limit//1
      do {Enum.at(s, i), Enum.at(s, j)} end |>
      Enum.reduce({%{}, %{}}, fn {pi, pj}, {dist_n, uniq_n} ->
        d = Enum.zip_with(pi, pj, calc_d) |> Enum.sum
        uniq_n = Enum.reduce([pi, pj], uniq_n, fn p, uniq_n ->
                 Map.update(uniq_n, p, [d], &[d | &1]) end)
        {Map.put(dist_n, d, [pi, pj]), uniq_n}
      end)
    # convert uniq to string, keeping only the two closest neighbors
    {uniq_n, ct} =
      Enum.reduce(uniq_n, {uniq_n, ct}, fn {k, v}, {uniq_n, ct} ->
        u = Enum.sort(v) |> Enum.take(2) |> Enum.join(",")
        {Map.put(uniq_n, k, u), MapSet.put(ct, u)}
      end)
    {Map.put(dist, n, dist_n), Map.put(unique, n, uniq_n), ct}
  end) |>
  then(fn {dist, unique, ct} -> %{dist: dist, unique: unique, ct: ct} end)

IO.puts("Part 1: #{MapSet.size(info.ct)}")


# Now info.dist contains keys of point distances and values of the two
# points that the distance is between, whereas our "fingerprint" hash
# info.unique has keys of point coordinates (in list form) and values of the
# distances from that point to its two nearest neighbors (in string form).
# Each is further keyed on scanner ID, since each scanner has a different
# system of coordinates, which we need to now reconcile with each other.
#
# For any system where we don't know the origin, we need
# to be able to express its points in all possible orientations
# and see which orientation resolves to a single translation
# vector from the values of the points with known origin.
rotations = fn [x, y, z] -> Enum.concat([
  for {j, k} <- [{y, z}, {z, -y}, {-y, -z}, {-z, y}] do [x, j, k] end,
  for {j, k} <- [{-y, z}, {-z, -y}, {y, -z}, {z, y}] do [-x, j, k] end,
  for {j, k} <- [{-x, z}, {z, x}, {x, -z}, {-z, -x}] do [y, j, k] end,
  for {j, k} <- [{x, z}, {-z, x}, {-x, -z}, {z, -x}] do [-y, j, k] end,
  for {j, k} <- [{y, -x}, {x, y}, {-y, x}, {-x, -y}] do [z, j, k] end,
  for {j, k} <- [{-y, -x}, {-x, y}, {y, x}, {x, -y}] do [-z, j, k] end ])
end

assign_points = fn id, match, u_pts, info ->
  Enum.reduce(info.dist[id][match], u_pts, fn p, u_pts ->
    Map.put(u_pts, info.unique[id][p], p)
  end)
end

test_translation = fn k_points, u_rots, n ->
  Enum.reduce(k_points, MapSet.new, fn {idx, k_p}, trans ->
    u_p = Map.fetch!(u_rots, idx) |> Enum.at(n)
    MapSet.put(trans, Enum.zip_with(k_p, u_p, &-/2))
  end)
end

# "matches" is a list of distance keys that appear on both scanners
# (k is for "known" and u is for "unknown" system of reference)
find_translation = fn u_id, k_id, matches, info, found ->
  {u_points, k_points} =  # maps with key fingerprint, val coordinates
    Enum.reduce(matches, {%{}, %{}}, fn match, {u_points, k_points} ->
      {assign_points.(u_id, match, u_points, info),
       assign_points.(k_id, match, k_points, info)}
    end)
  u_rots = Map.new(u_points, fn {k, v} -> {k, rotations.(v)} end)
  trans =  # there are 24 possible 3D rotations
    Enum.reduce_while(0..23, nil, fn n, _ ->
      trans = test_translation.(k_points, u_rots, n)
      if MapSet.size(trans) != 1, do: {:cont, nil},
      else: {:halt, {MapSet.to_list(trans) |> hd, n}}
    end)
  if is_nil(trans) do raise(RuntimeError, "translation not found")
  else
    # Now we know the translation vector and its orientation!
    {t, n} = trans

    # That's the good news - the bad news is that we have to
    # update the values of the info map to place all of the
    # coordinates for this space in the common reference frame.
    info =
      Enum.reduce(info.dist[u_id], info, fn {d, pts}, info ->
        pk_old = pts
        # do the rotation first, then the translation
        pts = Enum.map(pts, fn p -> Enum.at(rotations.(p), n) end) |>
              Enum.map(fn p -> Enum.zip_with(p, t, &+/2) end)
        dist_u = Map.put(info.dist[u_id], d, pts)
        uniq_u = Enum.zip(pk_old, pts) |>
          Enum.reduce(info.unique[u_id], fn {old, new}, uniq_u ->
            {v, uniq_u} = Map.pop(uniq_u, old)
            if is_nil(v), do: uniq_u, else: Map.put(uniq_u, new, v)
          end)
        %{info | dist: Map.put(info.dist, u_id, dist_u),
                 unique: Map.put(info.unique, u_id, uniq_u)}
      end)
    # t also describes the scanner's position
    {info, Map.put(found, u_id, t)}
  end
end

# We are taking scanner 0 as our point of origin. Iteratively search
# for other scanners that have "at least 12 of the same beacons" which
# isn't entirely clear how to extrapolate for number of distances, but
# testing on the example where we know 0 and 1 overlap, the desired
# number of matches seems to be 66. More than that and the search fails.
# ** Noting some math here: ( 12 * 11 ) / 2 = 66 **
find_overlap = fn s, dist, found ->
  Enum.reduce(Map.keys(found), %{}, fn f, overlap ->
    matches = Map.keys(dist[s]) |> Enum.filter(&Map.has_key?(dist[f], &1))
    if length(matches) != 66, do: overlap, else: Map.put(overlap, f, matches)
  end)
end

# drop the inputs, keep the index values
data = Enum.map(data, fn {_, n} -> n end)

found =
  Enum.reduce_while(Stream.cycle([1]), {info, %{0 => [0,0,0]}, tl(data)},
  fn _, {info, found, search} ->
    if Enum.empty?(search) do {:halt, found}
    else
      Enum.reduce_while(Enum.sort(search), {info, found, search},
      fn s, {info, found, search} ->
        overlap = find_overlap.(s, info.dist, found)
        if Enum.empty?(overlap) do {:cont, {info, found, search}}
        else
          [{f, matches}] = Enum.take(overlap, 1)
          {info, found} = find_translation.(s, f, matches, info, found)
          {:halt, {info, found, List.delete(search, s)}}
        end
      end) |> then(&{:cont, &1})
    end
  end) |> Map.new(fn {k, v} -> {k, List.to_tuple(v)} end)

# Now that we've adjusted the frame of reference for each scanner,
# we can determine how far apart the scanners all are from each other.
largest_scanner_distance =
  for i <- data, j <- data do Util.m_dist(found[i], found[j]) end |> Enum.max

IO.puts("Part 2: #{largest_scanner_distance}")
