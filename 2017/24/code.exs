# Solution to Advent of Code 2017, Day 24
# https://adventofcode.com/2017/day/24

Code.require_file("Util.ex", "..")
Code.require_file("Recurse.ex", ".")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

data = read_input.() |> Enum.map(&Util.read_numbers/1)

IO.puts("Part 1: #{Recurse.strongest(data) |> elem(0)}")
IO.puts("Part 2: #{Recurse.longest(data) |> elem(1) |> Recurse.strength}")

# elapsed time: approx. 1.5 sec for both parts together
