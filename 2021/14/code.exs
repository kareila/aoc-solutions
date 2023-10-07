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
  gs = String.graphemes(line)
  Enum.zip_with(gs, tl(gs), fn a, b -> a <> b end) |> Enum.frequencies
end

parse_input = fn [start | lines] ->
  %{start: start, freq: parse_freq.(start),
    rules: Map.new(lines, parse_rules)}
end

m_merge = fn m1, m2 -> Map.merge(m1, m2, fn _, v1, v2 -> v1 + v2 end) end

data = read_input.() |> parse_input.()

do_insertion = fn _, freq ->
  pk = fn {k, v} -> Map.fetch!(data.rules, k) |> Map.from_keys(v) end
  Enum.map(freq, pk) |> Enum.reduce(m_merge)
end

tuple_diff = fn {least, most} -> most - least end

calc = fn n ->
  # count the first element of each pair, since pairs overlap
  sk = fn {k, v} -> Map.new([{String.first(k), v}]) end
  Enum.reduce(1..n, data.freq, do_insertion) |>
  Enum.map(sk) |> Enum.reduce(m_merge) |>
  # the last char of the string is the odd one out, make sure to count it
  Map.update(String.last(data.start), 1, &(&1 + 1)) |>
  Map.values |> Enum.min_max |> tuple_diff.()
end

IO.puts("Part 1: #{calc.(10)}")
IO.puts("Part 2: #{calc.(40)}")
