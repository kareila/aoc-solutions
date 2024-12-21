# Solution to Advent of Code 2024, Day 20
# https://adventofcode.com/2024/day/20

Code.require_file("Matrix.ex", "..")
Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_input = fn lines ->
  grid = Matrix.map(lines)
  keys = Util.group_tuples(grid, 1, 0)
  [[start], [stop]] = [Map.fetch!(keys, "S"), Map.fetch!(keys, "E")]
  open = [start, stop] ++ Map.fetch!(keys, ".") |> MapSet.new
  %{grid: grid, start: start, open: open, path: nil}
end

find_path = fn data ->
  init = {data.open, data.start, %{}, 0}
  Enum.reduce(data.open, init, fn _, {open, pos, path, steps} ->
    [path, open] = [Map.put(path, pos, steps), MapSet.delete(open, pos)]
    pos = Util.adj_pos(pos) |> Enum.find(& &1 in open)
    {open, pos, path, steps + 1}
  end) |> elem(2)
end

generate_region = fn pos, n ->
  Enum.reduce(1..n, {[pos], %{pos => 0}}, fn d, {edge, region} ->
    edge =
      Enum.flat_map(edge, &Util.adj_pos/1) |>
      Enum.reject(&is_map_key(region, &1)) |> Enum.uniq
    {edge, Map.new(edge, fn e -> {e, d} end) |> Map.merge(region)}
  end) |> elem(1)
end

cheat_pos = fn pos, path, n ->
  Enum.flat_map(generate_region.(pos, n), fn {p, t} ->
    cond do
      not is_map_key(path, p) -> []
      path[pos] + t > path[p] -> []
      true -> [{{pos, p}, path[p] - path[pos] - t}]
    end
  end)
end

all_cheats = fn path, v, n ->
  if n > 2 do
    Task.async_stream(path, fn {p, _} -> cheat_pos.(p, path, n) end) |>
    Enum.flat_map(fn {:ok, vals} -> vals end)
  else  # less efficient to async smaller jobs
    Enum.flat_map(path, fn {p, _} -> cheat_pos.(p, path, n) end)
  end |> Enum.reject(fn {_, c} -> c < v end) |>
  Util.group_tuples(1) |> Enum.map(fn {_, s} -> length(s) end) |> Enum.sum
end

path = read_input.() |> parse_input.() |> find_path.()

IO.puts("Part 1: #{all_cheats.(path, 100, 2)}")
IO.puts("Part 2: #{all_cheats.(path, 100, 20)}")

# elapsed time: approx. 5.7 sec for both parts together
