# Solution to Advent of Code 2022, Day 1
# https://adventofcode.com/2022/day/1

# returns a list of text blocks from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n\n", trim: true)
end

# add together all the numbers in the block (one per line)
parse_block = fn block ->
  String.split(block, "\n", trim: true) |>
  Enum.map(&String.to_integer/1) |> Enum.sum
end

totals = read_input.() |> Enum.map(parse_block) |> Enum.sort(:desc)

IO.puts("Part 1: #{Enum.take(totals, 1) |> Enum.sum}")
IO.puts("Part 2: #{Enum.take(totals, 3) |> Enum.sum}")
