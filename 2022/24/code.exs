# Solution to Advent of Code 2022, Day 24
# https://adventofcode.com/2022/day/24

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

init_data = fn lines ->
  grid = matrix.(lines)
  [max_x, max_y] = [max_x.(grid), max_y.(grid)]
  start_row = lines |> hd |> String.graphemes
  goal_row = lines |> Enum.reverse |> hd |> String.graphemes
  [start_x, goal_x] = for row <- [start_row, goal_row],
    do: Enum.find_index(row, &(&1 == "."))
  %{grid: grid |> matrix_map.(), max_x: max_x, max_y: max_y, minutes: 0,
    start_point: {start_x, 0}, goal_point: {goal_x, max_y}}
end

# The value of a point in the grid occupied by blizzards needs
# to be a list, to allow for multiple blizzards occupying
# the same space at the same time. Blizzards wrap around the
# grid at the edges, and there are no interior walls.
advance_blizzard = fn {x,y}, data, new_grid ->
  case Map.get(data.grid, {x,y}) do
    nil -> new_grid
    "." -> new_grid
    "#" -> new_grid
    v ->
      v = if not is_list(v), do: [v], else: v
      Enum.reduce(v, new_grid, fn b, new_grid ->
        {x,y} =
          case b do
            "<" -> {if(x == 1, do: data.max_x, else: x) - 1, y}
            ">" -> {if(x == data.max_x - 1, do: 0, else: x) + 1, y}
            "^" -> {x, if(y == 1, do: data.max_y, else: y) - 1}
            "v" -> {x, if(y == data.max_y - 1, do: 0, else: y) + 1}
            b -> raise RuntimeError, "Invalid grid value #{b}"
          end
        v = Map.get(new_grid, {x,y}, [])
        v = if not is_list(v), do: [b], else: [b | v]
        Map.put(new_grid, {x,y}, v)
      end)
  end
end

tick = fn data ->
  pts = for j <- 1..data.max_y - 1, i <- 1..data.max_x - 1, do: {i,j}
  new_grid = Enum.reduce(pts, %{}, fn {i,j}, new_grid ->
    advance_blizzard.({i,j}, data, new_grid)
  end)
  grid = Enum.reduce(pts, data.grid, fn {i,j}, grid ->
    Map.put(grid, {i,j}, Map.get(new_grid, {i,j}, "."))
  end)
  %{data | grid: grid, minutes: data.minutes + 1}
end

_view_grid = fn data ->
  p = fn k ->
    case data.grid[k] do
      v when not is_list(v) -> v
      v when length(v) == 1 -> hd(v)
      v -> length(v)
    end
  end
  Enum.map_join(0..data.max_y, "\n", fn j ->
    Enum.map_join(0..data.max_x, fn i -> p.({i,j}) end)
  end) |> IO.puts
end

possible_moves = fn {x,y}, data ->
  pts = [ {x, y}, {x - 1, y}, {x + 1, y}, {x, y - 1}, {x, y + 1} ]
  Enum.map(pts, &Map.get(data.grid, &1)) |> Enum.zip(pts) |>
  Enum.flat_map(fn {v,k} -> if v == ".", do: [k], else: [] end)
end

# If this is a dead end, the result is an empty list.
next_steps = fn {x,y}, data ->
  Enum.reduce_while(possible_moves.({x,y}, data), [], fn p, possible ->
    # Can we reach our destination?
    if p == data.goal_point, do: {:halt, [p]},
    else: {:cont, [p | possible]}
  end)
end

walk_map = fn data ->
  paths = [data.start_point]
  Enum.reduce_while(Stream.cycle([1]), {paths, data}, fn _, {paths, data} ->
    data = tick.(data)
    # check all active paths at this point in time
    new_paths =
      Enum.reduce_while(paths, MapSet.new, fn {x,y}, new_paths ->
        next = next_steps.({x,y}, data)
        if next == [data.goal_point], do: {:halt, nil},
        else: {:cont, MapSet.union(new_paths, MapSet.new(next))}
      end)
    if new_paths == nil, do: {:halt, data},
    else: {:cont, {new_paths, data}}  # MapSets are enumerable too
  end)
end

data = read_input.() |> init_data.() |> walk_map.()

IO.puts("Part 1: #{data.minutes}")


# Keep going! Walk back to the start, then back to the goal.

data = %{data | start_point: data.goal_point, goal_point: data.start_point}
data = walk_map.(data)

IO.puts("Back to start: #{data.minutes}")

data = %{data | start_point: data.goal_point, goal_point: data.start_point}
data = walk_map.(data)

IO.puts("Part 2: #{data.minutes}")

# elapsed time: approx. 2.5 sec for both parts together
