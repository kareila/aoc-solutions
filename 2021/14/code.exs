# Solution to Advent of Code 2021, Day 14
# https://adventofcode.com/2021/day/14

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# The naive approach is to iterate with string substitutions, and
# this works for Part 1, but the string gets too long to handle
# after about 23 steps, which isn't adequate for Part 2. We only
# need to know the frequency of each element, not the full result.

parse_rules = fn line ->
  [pair, insert] = String.split(line, " -> ")
  [a, b] = String.graphemes(pair)
  {pair, [a <> insert, insert <> b]}
end

parse_freq = fn line ->
  chars = String.graphemes(line)
  Enum.zip([nil | chars], chars) |> tl |>
  Enum.map(fn {a, b} -> a <> b end) |> Enum.frequencies
end

parse_input = fn [start | lines] ->
  %{start: start, freq: parse_freq.(start),
    rules: Map.new(lines, parse_rules)}
end

data = read_input.() |> parse_input.()

do_insertion = fn freq ->
  pk = fn {k, v} -> Enum.map(Map.fetch!(data.rules, k), &{&1, v}) end
  fv = fn {p, v}, next -> Map.update(next, p, v, &(&1 + v)) end
  Enum.flat_map(freq, pk) |> Enum.reduce(%{}, fv)
end

diff = fn {least, most} -> most - least end

calc = fn n ->
  Enum.reduce(1..n, data.freq, fn _, freq -> do_insertion.(freq) end) |>
  # count the first element of each pair, since pairs overlap
  Enum.map(fn {k, v} -> Map.new([{String.first(k), v}]) end) |>
  Enum.reduce(%{}, &Map.merge(&2, &1, fn _, v1, v2 -> v1 + v2 end)) |>
  # the last char of the string is the odd one out, make sure to count it
  Map.update(String.last(data.start), 1, &(&1 + 1)) |>
  Map.values |> Enum.min_max |> diff.()
end

IO.puts("Part 1: #{calc.(10)}")
IO.puts("Part 2: #{calc.(40)}")
