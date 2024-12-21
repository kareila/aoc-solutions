# Solution to Advent of Code 2024, Day 18
# https://adventofcode.com/2024/day/18

Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_input = fn lines ->
  Enum.map(lines, fn s -> Util.read_numbers(s) |> List.to_tuple end)
end

init = %{start: {0, 0}, goal: {70, 70}, grid: %{}, best: %{}, bnum: 1024,
         bytes: read_input.() |> parse_input.()}


drop_bytes = fn bytes, data ->
  Enum.reduce(bytes, data, fn b, data ->
    %{data | grid: Map.put(data.grid, b, "#")}
  end)
end

simulate_bytes = fn data ->
  Enum.take(data.bytes, data.bnum) |> drop_bytes.(data)
end

path_init = fn %{start: start, goal: goal} ->
  {Util.m_dist(start, goal), 0, %{pos: start, visited: MapSet.new([start])}}
end

out_of_bounds = fn {px, py}, data ->
  [{sx, sy}, {gx, gy}] = [data.start, data.goal]
  px < sx or px > gx or py < sy or py > gy
end

possible_moves = fn %{pos: pos, visited: visited}, data ->
  Util.adj_pos(pos) |>
  Enum.reject(fn p -> Map.get(data.grid, p, ".") == "#" end) |>
  Enum.reject(fn p -> MapSet.member?(visited, p) end) |>
  Enum.reject(fn p -> out_of_bounds.(p, data) end) |>
  Enum.map(fn p -> {p, Util.m_dist(p, data.goal)} end) |>
  Enum.map(fn {p, d} ->
    {d, MapSet.size(visited), %{pos: p, visited: MapSet.put(visited, p)}}
  end) |> Enum.sort
end

cull = fn paths, data ->
  Enum.flat_map_reduce(paths, data, fn {d, sz, p}, data ->
    best = Map.get(data.best, p.pos)
    new_b = %{data | best: Map.put(data.best, p.pos, sz)}
    if is_nil(best) or best > sz, do: {[{d, sz, p}], new_b}, else: {[], data}
  end)
end

next_paths = fn paths, data ->
  [{_, _, path} | rest] = paths
  {nxt, data} = possible_moves.(path, data) |> cull.(data)
  {nxt ++ rest, data}
end

solve = fn data, fn_empty, fn_exit ->
  paths = [path_init.(data)]
  Enum.reduce_while(Stream.cycle([1]), {paths, data},
  fn _, {paths, data} ->
    {paths, data} = next_paths.(paths, data)
    if Enum.empty?(paths) do fn_empty.(data)
    else
      {d, _, _} = hd(paths)
      if d != 0, do: {:cont, {paths, data}},
      else: fn_exit.(paths, data)
    end
  end)
end

solve_min = fn data ->
  fn_empty = fn data -> {:halt, data.best[data.goal]} end
  fn_exit = fn paths, data -> {:cont, {tl(paths), data}} end
  solve.(data, fn_empty, fn_exit)
end

IO.puts("Part 1: #{simulate_bytes.(init) |> solve_min.()}")

solve_first = fn data ->
  fn_empty = fn _ -> {:halt, false} end
  fn_exit = fn _, _ -> {:halt, true} end
  solve.(data, fn_empty, fn_exit)
end

drop_all = fn data -> drop_bytes.(data.bytes, data) end

find_cutoff = fn data ->
  Enum.reverse(data.bytes) |>
  Enum.reduce_while(data, fn b, data ->
    data = %{data | grid: Map.put(data.grid, b, ".")}
    if solve_first.(data), do: {:halt, b}, else: {:cont, data}
  end) |> Tuple.to_list |> Enum.join(",")
end

IO.puts("Part 2: #{drop_all.(init) |> find_cutoff.()}")

# elapsed time: approx. 1.9 sec for both parts together
