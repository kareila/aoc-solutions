# Solution to Advent of Code 2022, Day 12
# https://adventofcode.com/2022/day/12

Code.require_file("Matrix.ex", "..")
Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

grid = read_input.() |> Matrix.map

init_data = fn paths -> %{ paths: paths, visited: MapSet.new } end

reachable? = fn v_cur, v_nxt ->
  [<<i_cur::utf8>>, <<i_nxt::utf8>>] = [v_cur, v_nxt]  # codepoint values
  i_nxt <= i_cur + 1  # possible if it is no more than one level higher
end

filter_reachable = fn points, v ->
  Enum.filter(points, fn {_, pv} -> reachable?.(v, pv) end)
end

check_for_end = fn points, v_cur ->
  ends = Enum.filter(points, fn {_, pv} -> pv == "E" end)
  cond do
    Enum.empty?(ends) -> filter_reachable.(points, v_cur)
    reachable?.(v_cur, "z") -> ends  # ending point has 'z' value
    true -> (points -- ends) |> filter_reachable.(v_cur)
  end
end

next_steps = fn {xy, v}, data ->
  v = if(v == "S", do: "a", else: v)  # starting point has 'a' value
  nxt = Util.adj_pos(xy) |> Enum.reject(fn p -> p in data.visited end)
  Map.take(grid, nxt) |> Map.to_list |> check_for_end.(v)
end

evaluate_pos = fn {xy, v}, data ->
  visited = MapSet.put(data.visited, xy)  # not stored yet
  to_try = next_steps.({xy, v}, data)
  [cur_path | paths] = data.paths
  cond do
    xy in data.visited -> {:cont, %{data | paths: paths}}
    Enum.empty?(to_try) -> {:cont, %{data | visited: visited, paths: paths}}
    List.keyfind(to_try, "E", 1) -> {:halt, length(cur_path)}
    true -> new_paths = Enum.map(to_try, fn p -> [p | cur_path] end)
    {:cont, %{data | visited: visited, paths: paths ++ new_paths}}
  end
end

start_paths = fn start_vals, matrix ->
  for {xy, v} <- matrix, v in start_vals, do: [{xy, v}]
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
