# Solution to Advent of Code 2021, Day 7
# https://adventofcode.com/2021/day/7

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_line = fn line ->
  String.split(line, ",") |> Enum.map(&String.to_integer/1)
end

data = read_input.() |> hd |> parse_line.() |> Enum.frequencies
{p_min, p_max} = Map.keys(data) |> Enum.min_max

minimize_fuel = fn cost_fn ->
  Enum.map(p_min..p_max, fn i ->
    Enum.map(data, fn {p, c} -> c * cost_fn.(abs(p - i)) end) |> Enum.sum
  end) |> Enum.min
end

IO.puts("Part 1: #{minimize_fuel.(fn n -> n end)}")


cost_cache =
  Enum.reduce(1..p_max, %{0 => 0}, fn n, cache ->
    Map.put(cache, n, n + Map.fetch!(cache, n - 1))
  end)

cost_fn = fn n -> Map.fetch!(cost_cache, n) end

IO.puts("Part 2: #{minimize_fuel.(cost_fn)}")
