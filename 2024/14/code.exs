# Solution to Advent of Code 2024, Day 14
# https://adventofcode.com/2024/day/14

Code.require_file("Matrix.ex", "..")
Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_line = fn line ->
  [px, py, vx, vy] = Util.read_numbers(line)
  {{px, py}, {vx, vy}}
end

data = read_input.() |> Enum.map(parse_line)
{min_x, max_x, min_y, max_y} = Util.group_tuples(data, 0) |> Matrix.limits


# update position and wrap around edges if necessary
move_robot = fn {{px, py}, {vx, vy}} ->
  {nx, ny} = {px + vx, py + vy}
  nx = if nx < min_x, do: nx + (max_x - min_x + 1), else: nx
  nx = if nx > max_x, do: nx - (max_x - min_x + 1), else: nx
  ny = if ny < min_y, do: ny + (max_y - min_y + 1), else: ny
  ny = if ny > max_y, do: ny - (max_y - min_y + 1), else: ny
  {{nx, ny}, {vx, vy}}
end

move_all = fn _, d -> Enum.map(d, move_robot) end
tick = fn d, t -> Enum.reduce(1..t, d, move_all) end

# divide grid into quadrants and calculate the safety factor
quad_groups = fn d ->
  {quad_x, quad_y} = {div(max_x, 2), div(max_y, 2)}
  Enum.reduce(d, %{}, fn {{px, py}, _}, q ->
    cond do
      px == quad_x or py == quad_y -> q
      px < quad_x and py < quad_y -> Map.update(q, 1, 1, & &1 + 1)
      px > quad_x and py < quad_y -> Map.update(q, 2, 1, & &1 + 1)
      px < quad_x and py > quad_y -> Map.update(q, 3, 1, & &1 + 1)
      px > quad_x and py > quad_y -> Map.update(q, 4, 1, & &1 + 1)
    end
  end) |> Map.values |> Enum.product
end

IO.puts("Part 1: #{tick.(data, 100) |> quad_groups.()}")

# if the robots are drawing a picture, most of the robots should
# be standing next to at least 2 other occupied spaces

adj_check = fn d ->
  grid = Util.group_tuples(d, 0)
  Enum.map(d, fn {p, _} ->
    Util.sur_pos(p) |> Enum.count(&is_map_key(grid, &1))
  end) |> Enum.count(& &1 > 1)
end

find_tree = fn d ->
  sz = map_size(Util.group_tuples(d, 0)) / 2
  Enum.reduce_while(Stream.iterate(1, &(&1 + 1)), d, fn t, data ->
    d = tick.(data, 1)
    if adj_check.(d) > sz, do: {:halt, t}, else: {:cont, d}
  end)
end

IO.puts("Part 2: #{find_tree.(data)}")

# if you want to view the data, use this function w/ IO.puts
_print_sparse_map = fn d ->
  Util.group_tuples(d, 0, 1) |> Map.new(fn {k, v} -> {k, length(v)} end) |>
  Matrix.print_sparse_map
end

# elapsed time: approx. 2.8 sec for both parts together
