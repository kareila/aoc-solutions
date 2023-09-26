# Solution to Advent of Code 2017, Day 12
# https://adventofcode.com/2017/day/12

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

all_matches = fn str, pat ->
  Regex.scan(pat, str, capture: :all_but_first) |> Enum.concat
end

read_numbers = fn str ->
  all_matches.(str, ~r/(\d+)/) |> Enum.map(&String.to_integer/1)
end

parse_line = fn line ->
  [first | rest] = read_numbers.(line)
  {first, rest}
end

parse_input = fn input -> Map.new(input, parse_line) end

find_group = fn data, id ->
  Enum.reduce_while(Stream.cycle([1]), MapSet.new([id]), fn _, found ->
    nxt = Enum.flat_map(found, &Map.fetch!(data, &1)) |>
          MapSet.new |> MapSet.union(found)
    if MapSet.equal?(nxt, found), do: {:halt, found}, else: {:cont, nxt}
  end)
end

group_zero = fn data -> find_group.(data, 0) |> MapSet.size end

data = read_input.() |> parse_input.()

IO.puts("Part 1: #{group_zero.(data)}")


count_groups = fn data ->
  all_keys = Map.keys(data) |> MapSet.new
  Enum.reduce_while(Stream.iterate(1, &(&1 + 1)), {all_keys, MapSet.new},
  fn n, {search, found} ->
    found = MapSet.union(found, find_group.(data, hd(Enum.take(search, 1))))
    if MapSet.equal?(all_keys, found), do: {:halt, n},
    else: {:cont, {MapSet.difference(all_keys, found), found}}
  end)
end

IO.puts("Part 2: #{count_groups.(data)}")
