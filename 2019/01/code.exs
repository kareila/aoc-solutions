# Solution to Advent of Code 2019, Day 1
# https://adventofcode.com/2019/day/1

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

fuel_calc = fn line ->
  num = String.to_integer(line) |> div(3)
  num - 2
end

total1 = read_input.() |> Enum.map(fuel_calc) |> Enum.sum

IO.puts("Part 1: #{total1}")


fuel_calc_re = fn line ->
  Enum.reduce_while(Stream.cycle([1]), {line, 0}, fn _, {line, acc} ->
    val = fuel_calc.(line)
    if val > 0, do: {:cont, {"#{val}", acc + val}}, else: {:halt, acc}
  end)
end

total2 = read_input.() |> Enum.map(fuel_calc_re) |> Enum.sum

IO.puts("Part 2: #{total2}")
