# Solution to Advent of Code 2024, Day 10
# https://adventofcode.com/2024/day/10

Code.require_file("Matrix.ex", "..")
Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_elevations = fn list ->
  Enum.map(list, fn {x, y, s} -> {x, y, String.to_integer(s)} end)
end

grid = read_input.() |> Matrix.grid |> parse_elevations.()
data = Matrix.map(grid)


next_steps = fn p, n ->
  Util.adj_pos(p) |> Enum.filter(&(Map.get(data, &1, 0) == n))
end

find_paths = fn {x, y, _} ->
  Enum.reduce(1..9, %{{x, y} => 1}, fn n, paths ->
    Enum.reduce(Map.keys(paths), %{}, fn p, nxt ->
      Map.new(next_steps.(p, n), fn k -> {k, paths[p]} end) |>
      Map.merge(nxt, fn _, v1, v2 -> v1 + v2 end)
    end)
  end)
end

all_paths = Util.group_tuples(grid, 2) |> Map.get(0) |> Enum.map(find_paths)
count_paths = &(Map.values(&1) |> Enum.sum)

IO.puts("Part 1: #{Enum.map(all_paths, &map_size/1) |> Enum.sum}")
IO.puts("Part 2: #{Enum.map(all_paths, count_paths) |> Enum.sum}")
