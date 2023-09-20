# Solution to Advent of Code 2021, Day 13
# https://adventofcode.com/2021/day/13

# returns TWO SETS of lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n\n", trim: true) |>
  Enum.map(&String.split(&1, "\n", trim: true))
end

all_matches = fn str, pat ->
  Regex.scan(pat, str, capture: :all_but_first) |> Enum.concat
end

read_numbers = fn str ->
  all_matches.(str, ~r/(\d+)/) |> Enum.map(&String.to_integer/1)
end

parse_coords = fn lines ->
  Enum.map(lines, read_numbers) |> Enum.map(&List.to_tuple/1)
end

parse_instructions = fn lines ->
  Enum.map(lines, fn line ->
    [_, axis, n] = Regex.run(~r/\s([xy])=(\d+)$/, line)
    {axis, String.to_integer(n)}
  end)
end

parse_input = fn [coords, instructions] ->
  %{coords: parse_coords.(coords) |> MapSet.new,
    instructions: parse_instructions.(instructions)}
end

min_max_x = fn matrix -> Enum.map(matrix, &elem(&1,0)) |> Enum.min_max end
min_max_y = fn matrix -> Enum.map(matrix, &elem(&1,1)) |> Enum.min_max end

# Note: dots will never appear exactly on a fold line
fold_fn = fn val, coords, minmax, splitter, mapper ->
  max_n = MapSet.to_list(coords) |> minmax.() |> elem(1)
  Enum.reduce(max_n..(val + 1), coords, fn n, coords ->
    new_n = 2 * val - n
    {row, coords} = MapSet.split_with(coords, &splitter.(&1, n))
    Enum.reduce(row, coords, &MapSet.put(&2, mapper.(&1, new_n)))
  end)
end

fold_up = fn val, coords ->
  splitter = fn {_, y}, j -> y == j end
  mapper = fn {x, _}, new_j -> {x, new_j} end
  fold_fn.(val, coords, min_max_y, splitter, mapper)
end

fold_left = fn val, coords ->
  splitter = fn {x, _}, i -> x == i end
  mapper = fn {_, y}, new_i -> {new_i, y} end
  fold_fn.(val, coords, min_max_x, splitter, mapper)
end

do_fold = fn {axis, val}, coords ->
  case axis do
    "y" -> fold_up.(val, coords)
    "x" -> fold_left.(val, coords)
  end
end

data = read_input.() |> parse_input.()

fold_once = fn ->
  do_fold.(hd(data.instructions), data.coords) |> MapSet.size
end

IO.puts("Part 1: #{fold_once.()}")


# including a bunch of personal library routines to print the folded data
matrix_map = fn matrix ->
  for {x, y, v} <- matrix, into: %{}, do: { {x, y}, v }
end

normalize_grid = fn grid ->
  {x0, x1} = min_max_x.(grid)
  {y0, y1} = min_max_y.(grid)
  bg = for i <- x0 .. x1, j <- y0 .. y1, do: {i, j, "."}
  Map.merge(matrix_map.(bg), matrix_map.(grid))
end

order_points = fn grid ->
  List.keysort(grid, 0) |> Enum.group_by(&elem(&1,1)) |>
  Map.to_list |> List.keysort(0) |> Enum.map(&elem(&1,1))
end

print_map = fn m_map ->
  Enum.map_join(order_points.(Map.keys(m_map)), "\n",
    fn row -> Enum.map_join(row, &Map.fetch!(m_map, &1))
  end)
end

fold_all = fn ->
  Enum.reduce(data.instructions, data.coords, do_fold) |>
  Enum.map(fn {x, y} -> {x, y, "#"} end) |>
  normalize_grid.() |> print_map.()
end

IO.puts("Part 2:\n#{fold_all.()}\n")
