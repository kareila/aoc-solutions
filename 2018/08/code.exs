# Solution to Advent of Code 2018, Day 8
# https://adventofcode.com/2018/day/8

require Recurse  # for nodes() and node_sum()

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_input = fn line ->
  String.split(line) |> Enum.map(&String.to_integer/1) |> Recurse.nodes()
end

tree = read_input.() |> hd |> parse_input.()

IO.puts("Part 1: #{Recurse.node_sum(tree, 1)}")
IO.puts("Part 2: #{Recurse.node_sum(tree, 2)}")
