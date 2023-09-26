# Solution to Advent of Code 2017, Day 24
# https://adventofcode.com/2017/day/24

require Recurse

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

data = read_input.() |> Enum.map(read_numbers)

IO.puts("Part 1: #{Recurse.strongest(data) |> elem(0)}")
IO.puts("Part 2: #{Recurse.longest(data) |> elem(1) |> Recurse.strength}")

# elapsed time: approx. 1.5 sec for both parts together
