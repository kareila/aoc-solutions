# Solution to Advent of Code 2021, Day 13
# https://adventofcode.com/2021/day/13

Code.require_file("Matrix.ex", "..")
Code.require_file("Util.ex", "..")

# returns TWO SETS of lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n\n", trim: true) |>
  Enum.map(&String.split(&1, "\n", trim: true))
end

parse_coords = fn lines ->
  Enum.map(lines, &List.to_tuple(Util.read_numbers(&1)))
end

parse_instructions = fn lines ->
  Enum.map(lines, fn line ->
    [_, axis, n] = Regex.run(~r/\s([xy])=(\d+)$/, line)
    {axis, String.to_integer(n)}
  end)
end

parse_input = fn [coords, folds] ->
  %{coords: parse_coords.(coords), instructions: parse_instructions.(folds)}
end

# Note: dots will never appear exactly on a fold line
fold_fn = fn val, coords, minmax, splitter, mapper ->
  max_n = minmax.(coords) |> elem(1)
  Enum.reduce(max_n..(val + 1), coords, fn n, coords ->
    new_n = 2 * val - n
    {row, coords} = Enum.split_with(coords, &splitter.(&1, n))
    Enum.reduce(row, coords, &[mapper.(&1, new_n) | &2])
  end) |> Enum.uniq  # this is faster than using MapSet
end

fold_y = fn val, coords ->
  splitter = fn {_, y}, j -> y == j end
  mapper = fn {x, _}, new_j -> {x, new_j} end
  fold_fn.(val, coords, &Matrix.min_max_y/1, splitter, mapper)
end

fold_x = fn val, coords ->
  splitter = fn {x, _}, i -> x == i end
  mapper = fn {_, y}, new_i -> {new_i, y} end
  fold_fn.(val, coords, &Matrix.min_max_x/1, splitter, mapper)
end

do_fold = fn {axis, val}, coords ->
  Map.fetch!(%{"y" => fold_y, "x" => fold_x}, axis).(val, coords)
end

data = read_input.() |> parse_input.()

fold_once = fn ->
  do_fold.(hd(data.instructions), data.coords) |> length
end

IO.puts("Part 1: #{fold_once.()}")


fold_all = fn ->
  Enum.reduce(data.instructions, data.coords, do_fold) |>
  Map.from_keys("#") |> Matrix.print_sparse_map
end

IO.puts("Part 2:\n#{fold_all.()}\n")
