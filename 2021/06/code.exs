# Solution to Advent of Code 2021, Day 6
# https://adventofcode.com/2021/day/6

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_line = fn line ->
  String.split(line, ",") |> Enum.map(&String.to_integer/1)
end

data = read_input.() |> hd |> parse_line.() |> Enum.frequencies

iterate = fn data ->
  nxt = Map.to_list(data) |> Enum.map(fn {k, v} -> {k - 1, v} end) |> Map.new
  if not Map.has_key?(nxt, -1) do nxt
  else
    {expired, data} = Map.pop!(nxt, -1)
    Map.put(data, 8, expired) |> Map.update(6, expired, &(&1 + expired))
  end
end

advance_days = fn days ->
  Enum.reduce(1..days, data, fn _, data -> iterate.(data) end) |>
  Map.values |> Enum.sum
end

IO.puts("Part 1: #{advance_days.(80)}")
IO.puts("Part 2: #{advance_days.(256)}")
