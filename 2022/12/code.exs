# Solution to Advent of Code 2022, Day 12
# https://adventofcode.com/2022/day/12

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

grid = read_input.() |> matrix.()
grid_map = matrix_map.(grid)
point_value = fn p -> Map.get(grid_map, p, nil) end

init_data = fn paths -> %{ paths: paths, visited: MapSet.new } end

reachable? = fn v_cur, v_nxt ->
  [<<i_cur::utf8>>, <<i_nxt::utf8>>] = [v_cur, v_nxt]  # codepoint values
  i_nxt <= i_cur + 1  # possible if it is no more than one level higher
end

filter_reachable = fn points, v ->
  Enum.filter(points, fn {_, _, pv} -> reachable?.(v, pv) end)
end

check_for_end = fn points, v_cur ->
  ends = Enum.filter(points, fn {_, _, pv} -> pv == "E" end)
  cond do
    Enum.empty?(ends) -> filter_reachable.(points, v_cur)
    reachable?.(v_cur, "z") -> ends  # ending point has 'z' value
    true -> (points -- ends) |> filter_reachable.(v_cur)
  end
end

next_steps = fn {x, y, v}, data ->
  v = if(v == "S", do: "a", else: v)  # starting point has 'a' value
  [ {x - 1, y}, {x + 1, y}, {x, y - 1}, {x, y + 1} ]
  |> Enum.reject(fn p -> MapSet.member?(data.visited, p) end)
  |> Enum.map(fn p -> Tuple.append(p, point_value.(p)) end)
  |> Enum.reject(fn {_, _, pv} -> pv == nil end) |> check_for_end.(v)
end

evaluate_pos = fn {x, y, v}, data ->
  visited = MapSet.put(data.visited, {x, y})  # not stored yet
  possible = next_steps.({x, y, v}, data)
  [cur_path | paths] = data.paths
  cond do
    MapSet.member?(data.visited, {x, y}) -> {:cont, %{data | paths: paths}}
    Enum.empty?(possible) -> {:cont, %{data | visited: visited, paths: paths}}
    List.keyfind(possible, "E", 2) -> {:halt, length(cur_path)}
    true -> new_paths = Enum.map(possible, fn p -> [p | cur_path] end)
    {:cont, %{data | visited: visited, paths: paths ++ new_paths}}
  end
end

start_paths = fn start_vals, matrix ->
  for {x, y, v} <- matrix, v in start_vals, do: [{x, y, v}]
end

walk_map = fn matrix, start_vals ->
  data = start_paths.(start_vals, matrix) |> init_data.()
  Enum.reduce_while(Stream.cycle([1]), data, fn _, data ->
    hd(data.paths) |> hd |> evaluate_pos.(data)
  end)
end

walk = walk_map.(grid, ["S"])

IO.puts("Part 1: #{walk}")


# For Part 2, do the same calculation starting from every 'a' on the grid.

walk = walk_map.(grid, ["S", "a"])

IO.puts("Part 2: #{walk}")
