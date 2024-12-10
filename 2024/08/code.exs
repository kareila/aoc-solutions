# Solution to Advent of Code 2024, Day 8
# https://adventofcode.com/2024/day/8

Code.require_file("Matrix.ex", "..")
Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

grid = read_input.() |> Matrix.grid
data = Matrix.map(grid)


antinode_pair = fn {a, b, _}, {c, d, _} ->
  {x_diff, y_diff} = {(a - c), (b - d)}
  {x1, x2, y1, y2} = {a + x_diff, c - x_diff, b + y_diff, d - y_diff}
  [{x1, y1}, {x2, y2}] |> Enum.filter(&is_map_key(data, &1))
end

antinode_seq = fn [first | rest], pair_fn ->
  Enum.flat_map(rest, &pair_fn.(first, &1))
end

all_antinodes = fn list, pair_fn ->
  Enum.reduce(tl(list), {MapSet.new, list}, fn _, {found, search} ->
    new = antinode_seq.(search, pair_fn) |> MapSet.new
    {MapSet.union(new, found), tl(search)}
  end) |> elem(0)
end

calc_all = fn p_fn ->
  Util.group_tuples(grid, 2) |> Map.delete(".") |>
  Enum.flat_map(fn {_, v} -> all_antinodes.(v, p_fn) end) |> Enum.uniq
end

IO.puts("Part 1: #{calc_all.(antinode_pair) |> length}")

{x_min, x_max, y_min, y_max} = Matrix.limits(grid)

resonant_pair = fn {a, b, _}, {c, d, _} ->
  {x_diff, y_diff} = {abs(a - c), abs(b - d)}
  x1_list =
    if a < c, do: Range.new(c, x_min, -x_diff),
    else: Range.new(c, x_max, x_diff)
  x2_list =
    if a < c, do: Range.new(a, x_max, x_diff),
    else: Range.new(a, x_min, -x_diff)
  y1_list =
    if b < d, do: Range.new(d, y_min, -y_diff),
    else: Range.new(d, y_max, y_diff)
  y2_list =
    if b < d, do: Range.new(b, y_max, y_diff),
    else: Range.new(b, y_min, -y_diff)
  [Enum.zip(x1_list, y1_list), Enum.zip(x2_list, y2_list)] |> Enum.concat
end

IO.puts("Part 2: #{calc_all.(resonant_pair) |> length}")
