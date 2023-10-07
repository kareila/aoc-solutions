# Solution to Advent of Code 2021, Day 1
# https://adventofcode.com/2021/day/1

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

data = read_input.() |> Enum.map(&String.to_integer/1)

increases = Enum.zip(data, tl(data)) |> Enum.count(fn {a, b} -> a < b end)

IO.puts("Part 1: #{increases}")


window_increases =
  Enum.count(1..(length(data) - 3), fn i ->
    [a, b] = [Enum.slice(data, i - 1, 3), Enum.slice(data, i, 3)]
    Enum.sum(a) < Enum.sum(b)
  end)

IO.puts("Part 2: #{window_increases}")
