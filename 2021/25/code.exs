# Solution to Advent of Code 2021, Day 25
# https://adventofcode.com/2021/day/25

Code.require_file("Matrix.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_input = fn lines ->
  grid = Matrix.map(lines)
  # used for modulus arithmetic when wrapping edges
  {_, max_x, _, max_y} = Matrix.limits(grid)
  # ordered list of grid positions - doesn't change
  points = Matrix.order_points(grid) |> List.flatten
  %{grid: grid, max_x: max_x, max_y: max_y, points: points}
end

advance = fn this_pos, next_pos, v, data ->
  next_v = Map.get(data.grid, next_pos, ".")
  this_v = Map.get(data.grid, this_pos, ".")
  if this_v != v or next_v != ".", do: [],
  else: [{this_pos, "."}, {next_pos, v}]
end

advance_right = fn {x, y}, data ->
  next_x = Integer.mod(x + 1, data.max_x + 1)
  advance.({x, y}, {next_x, y}, ">", data)
end

advance_down = fn {x, y}, data ->
  next_y = Integer.mod(y + 1, data.max_y + 1)
  advance.({x, y}, {x, next_y}, "v", data)
end

advance_all = fn data, afun ->
  grid = Enum.flat_map(data.points, &afun.(&1, data)) |> Map.new
  %{data | grid: Map.merge(data.grid, grid)}
end

tick = fn data ->
  data |> advance_all.(advance_right) |> advance_all.(advance_down)
end

find_repeat = fn data ->
  Enum.reduce_while(Stream.iterate(1, &(&1 + 1)), data, fn t, data ->
    current_state = data.grid
    data = tick.(data)
    if data.grid == current_state, do: {:halt, t}, else: {:cont, data}
  end)
end

data = read_input.() |> parse_input.()

IO.puts("Part 1: #{find_repeat.(data)}")

# elapsed time: approx. 3.5 sec

# There is no Part 2!  Merry Christmas!
