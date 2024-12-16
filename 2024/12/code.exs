# Solution to Advent of Code 2024, Day 12
# https://adventofcode.com/2024/day/12

Code.require_file("Matrix.ex", "..")
Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

grid = read_input.() |> Matrix.map


examine_plot = fn pos ->
  type = Map.fetch!(grid, pos)
  Enum.reduce(Util.adj_pos(pos), %{same: [], diff: []}, fn {x, y}, result ->
    if Map.get(grid, {x, y}) == type do
      %{result | same: [{x, y} | result.same]}
    else  # same position can border multiple edges
      %{result | diff: [{x, y, pos} | result.diff]}
    end
  end)
end

examine_region = fn pos ->
  result = %{area: MapSet.new([pos]), edges: []}
  Enum.reduce_while(Stream.cycle([1]), {result, [pos]}, fn _, {result, p} ->
    if Enum.empty?(p) do {:halt, result}
    else
      [pos | p] = p
      %{same: s, diff: d} = examine_plot.(pos)
      s = Enum.filter(s, & &1 not in result.area)
      area = MapSet.new(s) |> MapSet.union(result.area)
      {:cont, {%{result | area: area, edges: d ++ result.edges}, s ++ p}}
    end
  end)
end

examine_map = fn ->
  locs = Map.keys(grid) |> MapSet.new
  Enum.reduce_while(Stream.cycle([1]), {locs, []}, fn _, {locs, regions} ->
    if Enum.empty?(locs) do {:halt, regions}
    else
      result = MapSet.to_list(locs) |> hd |> examine_region.()
      {:cont, {MapSet.difference(locs, result.area), [result | regions]}}
    end
  end)
end

data = examine_map.()

calc_price = fn %{area: a, edges: e} -> MapSet.size(a) * length(e) end

IO.puts("Part 1: #{Enum.map(data, calc_price) |> Enum.sum}")

# figure out which edges contain consecutive runs of fencing...
# this works well and quickly, but later realized that detecting
# corners during the initial mapping would probably be simpler

count_consecutive_num = fn list, xy ->
  seq = Enum.map(list, &elem(&1, 1 - xy)) |> Enum.sort
  Enum.zip(seq, tl(seq)) |> Enum.count(fn {a, b} -> b - a == 1 end)
end

# group by edge facing, then by row/column, before counting
reduce_edges = fn edges ->
  Enum.group_by(edges, fn {dx, dy, {px, py}} -> {dx - px, dy - py} end) |>
  Enum.flat_map(fn {{x_diff, _}, list} ->
    xy = if x_diff == 0, do: 1, else: 0
    Util.group_tuples(list, xy) |> Map.values |>
    Enum.map(&count_consecutive_num.(&1, xy))
  end) |> Enum.sum
end

bulk_price = fn %{area: a, edges: e} = region ->
  calc_price.(region) - MapSet.size(a) * reduce_edges.(e)
end

IO.puts("Part 2: #{Enum.map(data, bulk_price) |> Enum.sum}")
