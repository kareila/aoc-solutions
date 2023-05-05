# Solution to Advent of Code 2022, Day 4
# https://adventofcode.com/2022/day/4

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# In this exercise, each line contains 4 integers that describe 2 ranges.
# Our assignment is to detect how the ranges overlap each other.
parse_line = fn line ->
  Regex.run(~r/^(\d+)\-(\d+),(\d+)\-(\d+)$/, line) |> tl
  |> Enum.map(&String.to_integer/1)
end

# One range fully contains the other if start is <= and end is >=
contained? = fn [a1, a2, b1, b2] ->
  (a1 <= b1 and a2 >= b2) or (b1 <= a1 and b2 >= a2)
end

data = read_input.() |> Enum.map(parse_line)
total = Enum.count(data, contained?)

IO.puts("Part 1: #{total}")


# For the second part, count any overlaps, not just total ones.
overlapping? = fn [a1, a2, b1, b2] ->
  seq = Enum.concat(a1..a2, b1..b2)
  Enum.count(seq) != Enum.count(Enum.uniq(seq))
end

total = Enum.count(data, overlapping?)

IO.puts("Part 2: #{total}")
