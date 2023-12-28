# Solution to Advent of Code 2023, Day 23
# https://adventofcode.com/2023/day/23

Code.require_file("Matrix.ex", "..")
Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

init_data = fn lines ->
  grid = Matrix.map(lines)
  max_y = length(lines) - 1
  [start_x, goal_x] = for row <- [List.first(lines), List.last(lines)],
    do: Enum.find_index(String.graphemes(row), &(&1 == "."))
  %{grid: grid, start_point: {start_x, 0}, goal_point: {goal_x, max_y}}
end

possible_moves = fn {x, y}, data ->
  opts = Util.dir_pos({x, y})
  Enum.map(opts, &Map.get(data.grid, elem(&1,1))) |> Enum.zip(opts) |>
  Enum.flat_map(fn {v, {d, p}} ->
    cond do
      v == "." -> [p]
      v == "^" and d == "N" -> [p]
      v == "v" and d == "S" -> [p]
      v == ">" and d == "E" -> [p]
      v == "<" and d == "W" -> [p]
      true -> []
    end
  end)
end

next_steps = fn pos, %{goal_point: goal} = data ->
  possible = possible_moves.(pos, data)
  if goal in possible, do: [goal], else: possible
end

walk_map = fn data ->
  init = {[{data.start_point, MapSet.new}], nil}
  Enum.reduce_while(Stream.iterate(0, &(&1 + 1)), init, fn t, {paths, ft} ->
    if Enum.empty?(paths) do {:halt, ft}
    else
      ft = if Enum.any?(paths, fn {p, _} -> p == data.goal_point end),
           do: t, else: ft
      Enum.flat_map(paths, fn {pos, visited} ->
        visited = MapSet.put(visited, pos)
        Enum.reject(next_steps.(pos, data), &MapSet.member?(visited, &1)) |>
        Enum.map(&{&1, visited})
      end) |> then(&{:cont, {&1, ft}})
    end
  end)
end

data = read_input.() |> init_data.()

IO.puts("Part 1: #{walk_map.(data)}")


remove_slopes = fn %{grid: grid} = data ->
  {walls, path} = Map.split_with(grid, &(elem(&1,1) == "#"))
  path = Map.keys(path) |> Map.from_keys(".")
  %{data | grid: Map.merge(path, walls)}
end

data = remove_slopes.(data)

# For Part 2 to be tractable, we have to think of this
# as a weighted graph with maze intersections as nodes.

select_nodes = fn data ->
  Util.group_tuples(data.grid, 1, 0) |> Map.fetch!(".") |>
  Enum.filter(fn p -> length(possible_moves.(p, data)) > 2 end)
end

node_paths = fn data ->
  nodes = select_nodes.(data) ++ [data.start_point, data.goal_point]
  Map.new(nodes, fn start ->
    Enum.map(possible_moves.(start, data), fn p ->
      Enum.reduce_while(Stream.iterate(1, &(&1 + 1)), {p, start},
      fn t, {pos, prev} ->
        if pos in nodes do {:halt, {t, pos}}
        else
          [nxt] = possible_moves.(pos, data) -- [prev]
          {:cont, {nxt, pos}}
        end
      end)
    end) |> then(&{start, &1})
  end)
end

path_val = fn p -> Enum.map(p, &elem(&1,0)) |> Enum.sum end

next_nodes = fn {path, visited}, node_map ->
  pos = elem(hd(path), 1)
  [nxt, visited] = [Map.fetch!(node_map, pos), [pos | visited]]
  Enum.reject(nxt, fn {_, p} -> p in visited end) |>
  Enum.map(&{[&1 | path], visited})
end

walk_nodes = fn init, node_map, %{goal_point: goal} ->
  Enum.reduce_while(Stream.cycle([1]), {[init], 0}, fn _, {paths, best} ->
    if Enum.empty?(paths) do {:halt, best}
    else
      [{[{_, pos} | _] = path, visited} | paths] = paths
      nxt = next_nodes.({path, visited}, node_map)
      cond do
        pos == goal -> {:cont, {paths, Enum.max([best, path_val.(path)])}}
        Enum.empty?(nxt) -> {:cont, {paths, best}}
        true -> {:cont, {nxt ++ paths, best}}
      end
    end
  end)
end

# Further algorithmic optimization options are hard to come by, but
# we can speed things up a bit by generating some parallel threads.
async_walk = fn data ->
  node_map = node_paths.(data)
  start = Map.fetch!(node_map, data.start_point)
  paths = next_nodes.({start, []}, node_map) |>
          Enum.flat_map(&next_nodes.(&1, node_map))
  walk_task = fn p -> walk_nodes.(p, node_map, data) end
  task_opts = [timeout: :infinity, ordered: false]
  for {:ok, best} <- Task.async_stream(paths, walk_task, task_opts)
    do best end |> Enum.max
end

IO.puts("Part 2: #{async_walk.(data)}")

# elapsed time: approx. 5 sec for both parts together
