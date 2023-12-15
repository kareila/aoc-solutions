# Solution to Advent of Code 2023, Day 11
# https://adventofcode.com/2023/day/11

Code.require_file("Matrix.ex", "..")
Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# this needs to be a sparse map - only keep the galaxy locations
grid = read_input.() |> Matrix.map |>
       Map.filter(fn {_, v} -> v == "#" end) |> Map.keys

{_, x_max, _, y_max} = Matrix.limits(grid)

list_empty = fn grid, limit, e_fn ->
  Range.to_list(limit..0) -- Enum.uniq(Enum.map(grid, e_fn))
end

expand = fn grid, limit, e_fn, p_fn ->
  Enum.reduce(list_empty.(grid, limit, e_fn), grid, fn e, grid ->
    {stay, move} = Enum.split_with(grid, fn p -> e_fn.(p) < e end)
    stay ++ Enum.map(move, p_fn)
  end)
end

expand_rows = fn grid, inc ->
  expand.(grid, y_max, &elem(&1,1), fn {x, y} -> {x, y + inc} end)
end

expand_cols = fn grid, inc ->
  expand.(grid, x_max, &elem(&1,0), fn {x, y} -> {x + inc, y} end)
end

distances = fn grid, inc ->
  grid = grid |> expand_rows.(inc) |> expand_cols.(inc)
  Enum.reduce(grid, {grid, []}, fn g, {grid, dists} ->
    {tl(grid), dists ++ Enum.map(grid, &Util.m_dist(&1, g))}
  end) |> elem(1) |> Enum.sum
end

IO.puts("Part 1: #{distances.(grid, 1)}")
IO.puts("Part 2: #{distances.(grid, 999999)}")
