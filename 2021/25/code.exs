# Solution to Advent of Code 2021, Day 25
# https://adventofcode.com/2021/day/25

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# parses input as a grid of values
matrix = fn lines ->
  for {line, y} <- Enum.with_index(lines),
      {v, x} <- String.graphemes(line) |> Enum.with_index,
  do: {x, y, v}
end

matrix_map = fn matrix ->
  for {x, y, v} <- matrix, into: %{}, do: { {x, y}, v }
end

min_max_x = fn matrix -> Enum.map(matrix, &elem(&1,0)) |> Enum.min_max end
min_max_y = fn matrix -> Enum.map(matrix, &elem(&1,1)) |> Enum.min_max end

# returns a list of rows
order_points = fn grid ->
  List.keysort(grid, 0) |> Enum.group_by(&elem(&1,1)) |>
  Map.to_list |> List.keysort(0) |> Enum.map(&elem(&1,1))
end

parse_input = fn lines ->
  grid = matrix.(lines)
  # used for modulus arithmetic when wrapping edges
  [max_x, max_y] = [elem(min_max_x.(grid), 1), elem(min_max_y.(grid), 1)]
  grid = matrix_map.(grid)
  # ordered list of grid positions - doesn't change
  points = Map.keys(grid) |> order_points.() |> List.flatten
  %{grid: grid, max_x: max_x, max_y: max_y, points: points}
end

advance = fn this_pos, next_pos, v, data ->
  next_v = Map.get(data.grid, next_pos, ".")
  this_v = Map.get(data.grid, this_pos, ".")
  if this_v != v or next_v != ".", do: %{},
  else: Map.new([{this_pos, "."}, {next_pos, v}])
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
  grid =
    Enum.reduce(data.points, %{}, fn pos, output ->
      Map.merge(output, afun.(pos, data))
    end) |> then(&Map.merge(data.grid, &1))
  %{data | grid: grid}
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
