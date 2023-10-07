# Solution to Advent of Code 2021, Day 3
# https://adventofcode.com/2021/day/3

Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_cols = fn lines ->
  Enum.reduce(lines, %{}, fn line, counts ->
    String.graphemes(line) |> Enum.map(&String.to_integer/1) |>
    Util.list_to_map |> Map.merge(counts, fn _, v1, v2 -> v1 + v2 end)
  end) |> Enum.sort |> Enum.map(&elem(&1,1))
end

lines = read_input.()
data = parse_cols.(lines)

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
  Enum.reduce_while(0..(length(data) - 1), lines, fn col, lines ->
    search = Enum.map(lines, &String.slice(&1, col, 1)) |> Enum.zip(lines)
    mid = length(search) / 2  # not integer division!
    ct = Enum.count(search, fn {s, _} -> s == "1" end)
    keep = to_string(if ct < mid, do: 1 - crit, else: crit)
    lines = Util.group_tuples(search, 0, 1) |> Map.fetch!(keep)
    if length(lines) == 1, do: {:halt, hd(lines)}, else: {:cont, lines}
  end)
end

calc_two = fn ->
  [filter_vals.(1), filter_vals.(0)] |> multiply_codes.()
end

IO.puts("Part 2: #{calc_two.()}")
