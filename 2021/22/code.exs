# Solution to Advent of Code 2021, Day 22
# https://adventofcode.com/2021/day/22

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

all_matches = fn str, pat ->
  Regex.scan(pat, str, capture: :all_but_first) |> Enum.concat
end

read_numbers = fn str ->
  all_matches.(str, ~r/(-?\d+)/) |> Enum.map(&String.to_integer/1)
end

parse_line = fn line ->
  [flip, line] = String.split(line)
  [x1, x2, y1, y2, z1, z2] = read_numbers.(line)
  %{flip: flip, x: x1..x2, y: y1..y2, z: z1..z2}
end

check_limits = fn x, y, z, limit ->
  ok? = x.first < x.last and y.first < y.last and z.first < z.last
  if is_nil(limit), do: ok?, else: ok? and
  Enum.all?([x.first, y.first, z.first], fn n -> n <= limit end) and
  Enum.all?([x.last, y.last, z.last], fn n -> n >= -limit end)
end

switches = read_input.() |> Enum.map(parse_line)

init_cube = fn ->
  Enum.filter(switches, fn s -> check_limits.(s.x, s.y, s.z, 50) end) |>
  Enum.reduce(MapSet.new, fn s, cube ->
    ms = if s.flip == "on", do: &MapSet.union/2, else: &MapSet.difference/2
    for i <- s.x, j <- s.y, k <- s.z do {i, j, k} end |>
    MapSet.new |> then(&ms.(cube, &1))
  end)
end

IO.puts("Part 1: #{init_cube.() |> MapSet.size}")


# For Part 2, our area is going to be too large to manage as before.
# Instead, let's just look at the volumes defined by the switches.
overlap = fn switch_a, switch_b, flip ->
  x1 = [switch_a.x.first, switch_b.x.first] |> Enum.max
  y1 = [switch_a.y.first, switch_b.y.first] |> Enum.max
  z1 = [switch_a.z.first, switch_b.z.first] |> Enum.max
  x2 = [switch_a.x.last, switch_b.x.last] |> Enum.min
  y2 = [switch_a.y.last, switch_b.y.last] |> Enum.min
  z2 = [switch_a.z.last, switch_b.z.last] |> Enum.min
  if check_limits.(x1..x2, y1..y2, z1..z2, nil),
  do: %{flip: flip, x: x1..x2, y: y1..y2, z: z1..z2}, else: nil
end

map_overlaps = fn areas, s, flip ->
  Enum.map(areas, &overlap.(s, &1, flip)) |> Enum.reject(&is_nil/1)
end

# Here we track each "on" volume as well as the areas of overlap.
# Each positive overlap is added as a negative, so that it isn't
# counted twice. Same with negative overlaps added to positive.
make_cube = fn ->
  Enum.reduce(switches, {[], []}, fn s, {positive, negative} ->
    new_negative = map_overlaps.(positive, s, "off")
    new_positive = map_overlaps.(negative, s, "on")
    positive = if s.flip == "on", do: [s | positive], else: positive
    {positive ++ new_positive, negative ++ new_negative}
  end) |> Tuple.to_list |> Enum.concat
end

volume = fn s ->
  [Range.size(s.x), Range.size(s.y), Range.size(s.z)] |> Enum.product
end

# Each list element knows if it's on or off, so we can combine them here.
volume_total = fn switches ->
  Enum.map(switches, fn s ->
    if s.flip == "on", do: volume.(s), else: -volume.(s)
  end) |> Enum.sum
end

IO.puts("Part 2: #{make_cube.() |> volume_total.()}")

# elapsed time: approx. 1.7 sec for both parts together
