# Solution to Advent of Code 2024, Day 6
# https://adventofcode.com/2024/day/6

Code.require_file("Matrix.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

grid = read_input.() |> Matrix.grid
start = List.keyfind(grid, "^", 2) |> Tuple.delete_at(2)
data = %{info: Matrix.map(grid), pos: start, dir: :u, visited: MapSet.new}


# atoms are slightly faster than strings here
next_dir = fn %{dir: dir} ->
  Map.fetch!(%{u: :r, r: :d, d: :l, l: :u}, dir)
end

facing_pos = fn %{dir: dir, pos: {x, y}} ->
  case dir do
    :u -> {x, y - 1}
    :r -> {x + 1, y}
    :d -> {x, y + 1}
    :l -> {x - 1, y}
  end
end

eval_pos = fn data ->
  data = %{data | visited: MapSet.put(data.visited, data.pos)}
  next = facing_pos.(data)
  case Map.get(data.info, next) do
    nil -> MapSet.to_list(data.visited)
    "#" -> %{data | dir: next_dir.(data)}
    _ -> %{data | pos: next}
  end
end

walk_map = fn change, eval_fn, data ->
  data = if change == start, do: data, else:
         %{data | info: Map.put(data.info, change, "#")}
  Enum.reduce_while(Stream.cycle([1]), data, fn _, data ->
    data = eval_fn.(data)
    if is_map(data), do: {:cont, data}, else: {:halt, data}
  end)
end

steps = walk_map.(start, eval_pos, data)

IO.puts("Part 1: #{length(steps)}")

# For Part 2, let's save directions as well as positions, but only when
# encountering obstacles. If a visited spot reappears, we're in a loop.

eval_path = fn data ->
  next = facing_pos.(data)
  case Map.get(data.info, next) do
    nil -> false
    "#" ->
      path = {data.pos, data.dir}
      if MapSet.member?(data.visited, path) do true
      else
        visited = MapSet.put(data.visited, path)
        %{data | dir: next_dir.(data), visited: visited}
      end
    _ -> %{data | pos: next}
  end
end

# Also, to save time, only block positions that were traversed in Part 1.
loops = Enum.count(steps, &walk_map.(&1, eval_path, data))

IO.puts("Part 2: #{loops}")

# elapsed time: approx. 2.0 sec for both parts together
