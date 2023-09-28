# Solution to Advent of Code 2017, Day 21
# https://adventofcode.com/2017/day/21

Code.require_file("Matrix.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# I'm not sure how much using a MapSet helps, since the full grid is
# expanded into a list on every iteration, but it makes counting easier?
matrix_mapset = fn matrix ->
  for {x, y, v} <- matrix, v == "#", into: MapSet.new, do: {x, y}
end

init_square = String.split(".#./..#/###", "/") |> Matrix.grid

init_grid = %{sz: 3, data: matrix_mapset.(init_square)}

parse_line = fn line -> String.split(line, " => ") |> List.to_tuple end

rules = read_input.() |> Map.new(parse_line)

permutations2 = fn [a, b, c, d] ->
  [[a, b, c, d], [a, c, b, d], [d, c, b, a], [d, b, c, a],
   [b, a, d, c], [b, d, a, c], [c, d, a, b], [c, a, d, b]]
end

permutations3 = fn [a, b, c, d, e, f, g, h, i] ->
  [[a, b, c, d, e, f, g, h, i], [a, d, g, b, e, h, c, f, i],
   [c, f, i, b, e, h, a, d, g], [c, b, a, f, e, d, i, h, g],
   [i, h, g, f, e, d, c, b, a], [i, f, c, h, e, b, g, d, a],
   [g, d, a, h, e, b, i, f, c], [g, h, i, d, e, f, a, b, c]]
end

region_to_vals = fn {sx, sy}, sz, data ->  # rows first, then columns
  for j <- sy..(sy + sz - 1), i <- sx..(sx + sz - 1) do {i, j} end |>
  Enum.map(fn p -> if MapSet.member?(data, p), do: "#", else: "." end)
end

grid_to_str_p = fn topleft, sz, data ->
  perms = Map.fetch!(%{2 => permutations2, 3 => permutations3}, sz)
  region_to_vals.(topleft, sz, data) |> perms.() |> Enum.map(fn g ->
  Enum.chunk_every(g, sz) |> Enum.map_join("/", &Enum.join/1) end)
end

match_rule = fn list ->
  search = Map.keys(rules)
  Enum.find(list, fn s -> s in search end) |> then(&Map.fetch!(rules, &1))
end

# passing data as strings instead of matrix reduces runtime by 10%
# (I believe because the size of the full list is divided by 9)
assemble_regions = fn data, sz, rnum ->
  for {reg, j} <- Stream.chunk_every(data, rnum) |> Stream.with_index,
      {str, i} <- Stream.with_index(reg),
      {row, y} <- String.split(str, "/") |> Enum.with_index(j * sz),
      {val, x} <- String.graphemes(row) |> Enum.with_index(i * sz),
  val == "#", into: MapSet.new, do: {x, y}
end

replace_regions = fn grid ->
  sz = if rem(grid.sz, 2) == 0, do: 2, else: 3
  [n_sz, rnum] = [sz + 1, div(grid.sz, sz)]
  for j <- 1..grid.sz//sz, i <- 1..grid.sz//sz do {i - 1, j - 1} end |>
  # using Stream instead of Enum here saves us roughly another 10%
  Stream.map(fn p -> grid_to_str_p.(p, sz, grid.data) |> match_rule.() end) |>
  assemble_regions.(n_sz, rnum) |> then(&(%{data: &1, sz: n_sz * rnum}))
end

do_repeat = fn grid, n ->
  Enum.reduce(1..n, grid, fn _, grid -> replace_regions.(grid) end) |>
  then(&MapSet.size(&1.data))
end

IO.puts("Part 1: #{do_repeat.(init_grid, 5)}")
IO.puts("Part 2: #{do_repeat.(init_grid, 18)}")

# elapsed time: approx. 8.5 sec for both parts together
