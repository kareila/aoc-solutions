# Solution to Advent of Code 2022, Day 1
# https://adventofcode.com/2022/day/1

# returns a list of lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n")
end

# converts an input line to an integer (empty string is nil)
s_to_int = fn line ->
  if line == "", do: nil, else: String.to_integer(line)
end

data = read_input.() |> Enum.map(s_to_int) |> Enum.with_index

totals = Enum.reduce(data, %{0 => 0}, fn {line, lno}, totals ->
  curr_i = Map.keys(totals) |> Enum.max
  # Start a new collection every time we encounter a blank line.
  if line == nil, do: Map.put(totals, lno, 0), else:
  Map.put(totals, curr_i, totals[curr_i] + line)
end) |> Map.values |> Enum.sort(:desc)

slice_sum = fn list, range ->
  Enum.slice(list, range) |> Enum.sum
end

IO.puts("Part 1: #{slice_sum.(totals, 0..0)}")
IO.puts("Part 2: #{slice_sum.(totals, 0..2)}")
