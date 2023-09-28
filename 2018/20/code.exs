# Solution to Advent of Code 2018, Day 20
# https://adventofcode.com/2018/day/20

Code.require_file("Recurse.ex", ".")  # for traverse()

# input is one long line today
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.graphemes |> tl  # drop the leading ^
end

data = read_input.() |> Recurse.traverse |> Map.values

IO.puts("Part 1: #{Enum.max(data)}")
IO.puts("Part 2: #{Enum.count(data, &(&1 >= 1000))}")
