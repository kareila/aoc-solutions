# Solution to Advent of Code 2022, Day 20
# https://adventofcode.com/2022/day/20

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

inc_index = fn i, list -> if i >= length(list), do: 1, else: i + 1 end
dec_index = fn i, list -> if i <= 1, do: length(list), else: i - 1 end

# This version of the data structure is a map for performance reasons.
init_links = fn lines, mod_fn ->  # modifies given value (for Part 2)
  val_fn = fn x -> String.to_integer(x) |> mod_fn.() end
  Enum.with_index(lines, 1) |> Map.new(fn {l, i} ->
    {i, {val_fn.(l), inc_index.(i, lines), dec_index.(i, lines)}}
  end)
end

# Reduce the distance to travel by taking the modulus of the array length,
# minus one to remove the active node from consideration. Note we can't
# modify the node values in place, without risking multiple zero values.
mod_factor = fn v, max_i -> Integer.mod(abs(v), max_i) end

# Takes a list of nodes and shifts their assignments in one direction.
reassign = fn n_list, dir_fn, dir ->
  Enum.zip(n_list, Enum.map(Enum.slide(n_list, -1, 0), dir_fn))
  |> Enum.map(fn {n, v} -> put_elem(n, dir, v) end)
end

shift_node = fn n_i, links ->
  n = links[n_i]
  n_val = elem(n, 0)
  dist = mod_factor.(n_val, map_size(links) - 1)

  if dist == 0 do links
  else
    # Move node n from between m/o to between q/r. The meanings of
    # "forward" and "reverse" are inverted if n_val is negative.
    [fwd_dir, rev_dir] = if n_val > 0, do: [1, 2], else: [2, 1]

    # Using helper functions to make this easier to read.
    fwd = fn n -> elem(n, fwd_dir) end
    rev = fn n -> elem(n, rev_dir) end

    [o_i, o] = [fwd.(n), links[fwd.(n)]]
    [m_i, m] = [rev.(n), links[rev.(n)]]

    # Is forwards or backwards faster when seeking?
    # (This reduces total computation time by roughly half!)
    rev_dist = map_size(links) - dist
    q = if rev_dist > dist do
      Enum.reduce(2..dist//1, o, fn _, q -> links[fwd.(q)] end)
    else
      Enum.reduce(2..rev_dist//1, m, fn _, q -> links[rev.(q)] end)
    end

    [r_i, r] = [fwd.(q), links[fwd.(q)]]
    [q_i] = [rev.(r)]

    reassign_next = fn list -> reassign.(list, fwd, fwd_dir) end
    reassign_prev = fn list -> reassign.(list, rev, rev_dir) end

    [m, q, n] = reassign_next.([m, q, n])
    links = Map.merge(links, Map.new([{n_i, n}, {m_i, m}, {q_i, q}]))

    # we need to refetch these node values in case there was overlap
    # i.e. if dist is 1, q and o are the same node (alas no pointers)
    [o, r] = [links[o_i], links[r_i]]

    [o, r, n] = reassign_prev.([o, r, n])
    Map.merge(links, Map.new([{n_i, n}, {o_i, o}, {r_i, r}]))
  end
end

shift_all = fn links ->
  Enum.reduce(1..map_size(links), links, shift_node)
end

# find the node with value 0
find_origin = fn links ->
  Enum.find_value(links, fn {_, v} -> if elem(v, 0) == 0, do: v end)
end

sum_coordinates = fn links ->
  Enum.map_reduce(1..3000, find_origin.(links), fn i, n ->
    n = links[elem(n, 1)]
    {if rem(i, 1000) == 0 do elem(n, 0) else 0 end, n}
  end) |> elem(0) |> Enum.sum
end

links = read_input.() |> init_links.(fn x -> x end) |> shift_all.()

IO.puts("Part 1: #{sum_coordinates.(links)}")


# this is why mod_factor is our friend
links = read_input.() |> init_links.(fn x -> x * 811589153 end)
links = Enum.reduce(1..10, links, fn _, links -> shift_all.(links) end)

IO.puts("Part 2: #{sum_coordinates.(links)}")

# elapsed time: approx. 3.4 seconds for both parts together
