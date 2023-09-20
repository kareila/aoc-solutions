# Solution to Advent of Code 2021, Day 3
# https://adventofcode.com/2021/day/3

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_lines = fn lines ->
  Enum.reduce(lines, %{}, fn line, counts ->
    String.graphemes(line) |> Enum.map(&String.to_integer/1) |>
    Enum.with_index |> Map.new(fn {c, i} -> {i, c} end) |>
    Map.merge(counts, fn _, v1, v2 -> v1 + v2 end)
  end) |> Map.to_list |> List.keysort(0) |> Enum.map(&elem(&1,1))
end

lines = read_input.()
data = parse_lines.(lines)

multiply_codes = fn codes ->
  Enum.map(codes, &elem(Integer.parse(&1, 2), 0)) |> Enum.product
end

calc_one = fn ->
  mid = length(lines) / 2
  Enum.reduce(data, ["", ""], fn c, [gamma, epsilon] ->
    if c > mid, do: [gamma <> "1", epsilon <> "0"],
    else: [gamma <> "0", epsilon <> "1"]
  end) |> multiply_codes.()
end

IO.puts("Part 1: #{calc_one.()}")


filter_vals = fn crit ->
  init_idx = Enum.to_list(0..(length(lines) - 1))
  Enum.reduce_while(0..(length(data) - 1), init_idx, fn n, idx ->
    c = fn line -> String.slice(line, n, 1) |> String.to_integer end
    search = Map.new(idx, fn i -> {i, c.(Enum.at(lines, i))} end)
    ct = Map.values(search) |> Enum.sum
    mid = map_size(search) / 2  # not integer division!
    keep = if ct < mid, do: 1 - crit, else: crit
    idx = Map.filter(search, fn {_, v} -> v == keep end) |> Map.keys
    if length(idx) == 1, do: {:halt, idx}, else: {:cont, idx}
  end) |> hd |> then(&Enum.at(lines, &1))
end

calc_two = fn ->
  [filter_vals.(1), filter_vals.(0)] |> multiply_codes.()
end

IO.puts("Part 2: #{calc_two.()}")
