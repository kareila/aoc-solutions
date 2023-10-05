# Solution to Advent of Code 2020, Day 3
# https://adventofcode.com/2020/day/3

Code.require_file("Matrix.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

data = read_input.() |> Matrix.map

check_slope = fn {dx, dy} ->
  {x_min, x_max, y_min, y_max} = Matrix.limits(data)
  y_vals = Range.new(y_min, y_max, dy)
  Enum.reduce(y_vals, {x_min, 0}, fn y, {x, tot} ->
    x = rem(x, x_max + 1)
    tree = if Map.fetch!(data, {x, y}) == "#", do: 1, else: 0
    {x + dx, tot + tree}
  end) |> elem(1)
end

pt1 = check_slope.({3, 1})

IO.puts("Part 1: #{pt1}")


pt2 = [{1, 1}, {5, 1}, {7, 1}, {1, 2}] |>
  Enum.map(check_slope) |> Enum.reduce(pt1, &*/2)

IO.puts("Part 2: #{pt2}")
