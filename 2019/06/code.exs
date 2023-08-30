# Solution to Advent of Code 2019, Day 6
# https://adventofcode.com/2019/day/6

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_input = fn lines ->
  Enum.reduce(lines, %{}, fn line, orbits ->
    [a, b] = String.split(line, ")")
    Map.put(orbits, b, a)
  end)
end

list_orbits = fn p, orbits ->
  Enum.reduce_while(Stream.cycle([1]), {[], p}, fn _, {chain, p} ->
    if is_map_key(orbits, p), do: {:cont, {[p | chain], orbits[p]}},
    else: {:halt, chain}
  end)
end

count_orbits = fn p, orbits -> list_orbits.(p, orbits) |> length end

count_all = fn orbits ->
  Map.keys(orbits) |> Enum.map(&count_orbits.(&1, orbits)) |> Enum.sum
end

orbits = read_input.() |> parse_input.()

IO.puts("Part 1: #{count_all.(orbits)}")


divergence = fn list1, list2 ->
  Enum.reduce_while(Stream.cycle([1]), {list1, list2}, fn _, {l1, l2} ->
    if hd(l1) == hd(l2), do: {:cont, {tl(l1), tl(l2)}},
    else: {:halt, length(l1) + length(l2)}
  end)
end

l_you = list_orbits.(orbits["YOU"], orbits)
l_san = list_orbits.(orbits["SAN"], orbits)

IO.puts("Part 2: #{divergence.(l_you, l_san)}")
