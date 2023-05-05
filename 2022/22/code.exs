# Solution to Advent of Code 2022, Day 22
# https://adventofcode.com/2022/day/22

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

cols = fn matrix -> Enum.group_by(matrix, &elem(&1,0)) |> Map.values end
rows = fn matrix -> Enum.group_by(matrix, &elem(&1,1)) |> Map.values end
max_x = fn matrix -> Enum.count(cols.(matrix)) - 1 end
max_y = fn matrix -> Enum.count(rows.(matrix)) - 1 end

parse_lines = fn lines ->
  {path, lines} = List.pop_at(lines, -1)
  steps = String.split(path, ~r/[LR]/, include_captures: true) |>
    Enum.map_every(2, &String.to_integer/1)
  # initial position (keep this for reset later)
  init_x = hd(lines) |> String.graphemes |> Enum.find_index(&(&1 == "."))
  pos = %{facing: 0, y: 0, x: init_x}
  grid = matrix.(lines)
  [mx, my] = [max_x.(grid), max_y.(grid)]
  # we only need mx and my for static search range limits
  range = %{right: 0..mx-1//1, left: mx..1//-1,
             down: 0..my-1//1, up: my..1//-1}
  # removing spaces reduces the grid size by 25%
  grid = grid |> Enum.reject(&(elem(&1,2) == " ")) |> matrix_map.()
  %{steps: steps, pos: pos, init_x: init_x, grid: grid, range: range}
end

do_search = fn i, j, f, grid ->
  if Map.has_key?(grid, {i,j}), do: {:halt, {i, j, f}}, else: {:cont, nil}
end

search_right = fn y, data ->
  Enum.reduce_while(data.range.right, nil, fn i, _ ->
    do_search.(i, y, 0, data.grid) end) end

search_left = fn y, data ->
  Enum.reduce_while(data.range.left, nil, fn i, _ ->
    do_search.(i, y, 2, data.grid) end) end

search_down = fn x, data ->
  Enum.reduce_while(data.range.down, nil, fn j, _ ->
    do_search.(x, j, 1, data.grid) end) end

search_up = fn x, data ->
  Enum.reduce_while(data.range.up, nil, fn j, _ ->
    do_search.(x, j, 3, data.grid) end) end

wrap_around = fn data ->
  case data.pos.facing do
    # facing right: find the first tile to the right of the left edge
    0 -> search_right.(data.pos.y, data)
    # facing down: find the first tile below the top edge
    1 -> search_down.(data.pos.x, data)
    # facing left: find the first tile to the left of the right edge
    2 -> search_left.(data.pos.y, data)
    # facing up: find the first tile above the bottom edge
    3 -> search_up.(data.pos.x, data)
    v -> raise RuntimeError, "Invalid facing value #{v}"
  end
end

# return nil if we're blocked from moving
try_step = fn {x,y}, data ->
  case Map.get(data.grid, {x,y}) do
    "#" -> nil
    "." -> %{data | pos: %{data.pos | x: x, y: y}}
    _ -> data.wrap_around.(data)  # this returns a tuple
  end
end

# always returns data
do_step = fn {x,y}, data ->
  case try_step.({x,y}, data) do
    nil -> data
    moved when is_map(moved) -> moved
    # facing might change in Part 2 (no-op for Part 1)
    {i,j,f} ->
      case try_step.({i,j}, %{data | pos: %{data.pos | facing: f}}) do
        nil -> data
        moved when is_map(moved) -> moved
        _ -> raise RuntimeError, "Problem with wrap_around"
      end
    _ -> raise RuntimeError, "Problem with try_step"
  end
end

do_walk = fn n, data ->
  Enum.reduce(1..n, data, fn _, data ->
    {x,y} = case data.pos.facing do
      0 -> {data.pos.x + 1, data.pos.y + 0}
      1 -> {data.pos.x + 0, data.pos.y + 1}
      2 -> {data.pos.x - 1, data.pos.y - 0}
      3 -> {data.pos.x - 0, data.pos.y - 1}
      v -> raise RuntimeError, "Invalid facing value #{v}"
    end
    do_step.({x,y}, data)
  end)
end

do_turn = fn dir, data ->
  f = data.pos.facing
  f = case dir do
    "R" -> f + if f == 3, do: -3, else: 1
    "L" -> f - if f == 0, do: -3, else: 1
    v -> raise RuntimeError, "Invalid direction value #{v}"
  end
  %{data | pos: %{data.pos | facing: f}}
end

follow_steps = fn data ->
  Enum.reduce(data.steps, data, fn p, data ->
    if is_integer(p), do: do_walk.(p, data), else: do_turn.(p, data)
  end)
end

password = fn pos ->
  1000 * ( pos.y + 1 ) + 4 * ( pos.x + 1 ) + pos.facing
end

data = read_input.() |> parse_lines.()
# we need to cache wrap_around in data b/c it changes in Part 2
data = Map.put(data, :wrap_around, wrap_around) |> follow_steps.()

IO.puts("Part 1: #{password.(data.pos)}")


# Shape of actual data, reduced to 4x4 faces:
#
#     ........
#     ........
#     ........
#     ........
#     ....
#     ....
#     ....
#     ....
# ........
# ........
# ........
# ........
# ....
# ....
# ....
# ....
#
# Yep, we have to fold the grid into a cube...

data = %{data | pos: %{facing: 0, y: 0, x: data.init_x}}
    |> Map.put(:face_size, 50)

# The only method that needs to change is wrap_around.
# Note: this solution is designed only for the exact grid shape above.

wrap_around = fn data ->
  limits = Enum.map(1..4, fn n -> {n, n * data.face_size} end) |> Map.new
  mod_f = fn n -> Integer.mod(n, data.face_size) + 1 end
  [px, py] = [data.pos.x, data.pos.y]
  case data.pos.facing do
    # process all right edges from top to bottom
    0 ->
      cond do
        py < 0 -> raise RuntimeError, "y_pos #{py} out of bounds"
        # right edge of row 1 goes to right edge of row 3
        py < limits[1] -> limits[3] - mod_f.(py) |> search_left.(data)
        # right edge of row 2 goes to bottom edge of col 3
        py < limits[2] -> py + limits[1] |> search_up.(data)
        # right edge of row 3 goes to right edge of row 1
        py < limits[3] -> limits[1] - mod_f.(py) |> search_left.(data)
        # right edge of row 4 goes to bottom edge of col 2
        py < limits[4] -> py - limits[2] |> search_up.(data)
        true -> raise RuntimeError, "y_pos #{py} out of bounds"
      end
    # process all bottom edges from left to right
    1 ->
      cond do
        px < 0 -> raise RuntimeError, "x_pos #{px} out of bounds"
        # bottom edge of col 1 goes to top edge of col 3
        px < limits[1] -> px + limits[2] |> search_down.(data)
        # bottom edge of col 2 goes to right edge of row 4
        px < limits[2] -> px + limits[2] |> search_left.(data)
        # bottom edge of col 3 goes to right edge of row 2
        px < limits[3] -> px - limits[1] |> search_left.(data)
        true -> raise RuntimeError, "x_pos #{px} out of bounds"
      end
    # process all left edges from top to bottom
    2 ->
      cond do
        py < 0 -> raise RuntimeError, "y_pos #{py} out of bounds"
        # left edge of row 1 goes to left edge of row 3
        py < limits[1] -> limits[3] - mod_f.(py) |> search_right.(data)
        # left edge of row 2 goes to top edge of col 1
        py < limits[2] -> py - limits[1] |> search_down.(data)
        # left edge of row 3 goes to left edge of row 1
        py < limits[3] -> limits[1] - mod_f.(py) |> search_right.(data)
        # left edge of row 4 goes to top edge of col 2
        py < limits[4] -> py - limits[2] |> search_down.(data)
        true -> raise RuntimeError, "y_pos #{py} out of bounds"
      end
    # process all top edges from left to right
    3 ->
      cond do
        px < 0 -> raise RuntimeError, "x_pos #{px} out of bounds"
        # top edge of col 1 goes to left edge of row 2
        px < limits[1] -> px + limits[1] |> search_right.(data)
        # top edge of col 2 goes to left edge of row 4
        px < limits[2] -> px + limits[2] |> search_right.(data)
        # top edge of col 3 goes to bottom edge of col 1
        px < limits[3] -> px - limits[2] |> search_up.(data)
        true -> raise RuntimeError, "x_pos #{px} out of bounds"
      end
    v -> raise RuntimeError, "Invalid facing value #{v}"
  end
end

data = Map.put(data, :wrap_around, wrap_around) |> follow_steps.()

IO.puts("Part 2: #{password.(data.pos)}")
