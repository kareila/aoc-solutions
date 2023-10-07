# Solution to Advent of Code 2022, Day 24
# https://adventofcode.com/2022/day/24

Code.require_file("Matrix.ex", "..")
Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

init_data = fn lines ->
  grid = Matrix.map(lines)
  {_, max_x, _, max_y} = Matrix.limits(grid)
  [start_x, goal_x] = for row <- [List.first(lines), List.last(lines)],
    do: Enum.find_index(String.graphemes(row), &(&1 == "."))
  %{grid: grid, max_x: max_x, max_y: max_y, minutes: 0,
    start_point: {start_x, 0}, goal_point: {goal_x, max_y}}
end

mod_inc = fn i, max_i -> if i == max_i - 1, do: 1, else: i + 1 end
mod_dec = fn i, max_i -> if i == 1, do: max_i - 1, else: i - 1 end

# The value of a point in the grid occupied by blizzards needs
# to be a list, to allow for multiple blizzards occupying
# the same space at the same time. Blizzards wrap around the
# grid at the edges, and there are no interior walls.
advance_blizzard = fn {x, y}, data, new_grid ->
  v = Map.get(data.grid, {x, y}, ".")
  if v in [".", "#"] do new_grid
  else
    Enum.reduce(List.wrap(v), new_grid, fn b, new_grid ->
      pos =
        case b do
          "<" -> {mod_dec.(x, data.max_x), y}
          ">" -> {mod_inc.(x, data.max_x), y}
          "^" -> {x, mod_dec.(y, data.max_y)}
          "v" -> {x, mod_inc.(y, data.max_y)}
          b -> raise RuntimeError, "Invalid grid value #{b}"
        end
      Map.update(new_grid, pos, [b], &[b | &1])
    end)
  end
end

tick = fn data ->
  pts = for j <- 1..data.max_y - 1, i <- 1..data.max_x - 1, do: {i, j}
  new_grid = Enum.reduce(pts, %{}, &advance_blizzard.(&1, data, &2))
  grid = Map.merge(data.grid, Map.from_keys(pts, ".")) |> Map.merge(new_grid)
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

possible_moves = fn {x, y}, data ->
  pts = [{x, y} | Util.adj_pos({x, y})]
  Enum.map(pts, &Map.get(data.grid, &1)) |> Enum.zip(pts) |>
  Enum.flat_map(fn {v, k} -> if v == ".", do: [k], else: [] end)
end

# If this is a dead end, the result is an empty list.
next_steps = fn pos, data ->
  Enum.reduce_while(possible_moves.(pos, data), [], fn p, possible ->
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
      Enum.reduce_while(paths, MapSet.new, fn pos, new_paths ->
        next = next_steps.(pos, data)
        if next == [data.goal_point], do: {:halt, nil},
        else: {:cont, MapSet.union(new_paths, MapSet.new(next))}
      end)
    if is_nil(new_paths), do: {:halt, data},
    else: {:cont, {new_paths, data}}  # MapSets are enumerable too
  end)
end

data = read_input.() |> init_data.() |> walk_map.()

IO.puts("Part 1: #{data.minutes}")


# Keep going! Walk back to the start, then back to the goal.

flip = fn data ->
  %{data | start_point: data.goal_point, goal_point: data.start_point}
end

data = walk_map.(flip.(data))

IO.puts("Back to start: #{data.minutes}")

data = walk_map.(flip.(data))

IO.puts("Part 2: #{data.minutes}")

# elapsed time: approx. 2 sec for both parts together
