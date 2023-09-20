# Solution to Advent of Code 2021, Day 8
# https://adventofcode.com/2021/day/8

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# first, note which digits contain which segments
digits =
  %{0 => "abcefg", 1 => "cf", 2 => "acdeg", 3 => "acdfg", 4 => "bcdf",
    5 => "abdfg", 6 => "abdefg", 7 => "acf", 8 => "abcdefg", 9 => "abcdfg"}
  |> Map.new(fn {k, v} -> {k, String.graphemes(v)} end)

# second, note which digits contain a unique number of segments
unique_lengths = %{2 => 1, 3 => 7, 4 => 4, 7 => 8}  # seg => num

# additional analysis used in Part 2:
#  segment 'a' is turned off in 1, 4               (2)  (4: yes)
#  segment 'b' is turned off in 1, 2, 3, 7         (4)*
#  segment 'c' is turned off in 5, 6               (2)  (4: no)
#  segment 'd' is turned off in 0, 1, 7            (3)  (4: no)
#  segment 'e' is turned off in 1, 3, 4, 5, 7, 9   (6)*
#  segment 'f' is turned off in 2 only             (1)*
#  segment 'g' is turned off in 1, 4, 7            (3)  (4: yes)
#
# now try parsing input, noting that segment ordering is random
sort_segment = fn s -> Enum.sort(String.graphemes(s)) end
parse_seg = fn line -> Enum.map(String.split(line), sort_segment) end

parse_line = fn line ->
  [pats, vals] = String.split(line, " | ") |> Enum.map(parse_seg)
  %{pats: pats, vals: Enum.map(vals, &Enum.join/1)}
end

data = read_input.() |> Enum.map(parse_line)

calc_one = fn ->
  Enum.map(data, fn d -> Enum.count(d.vals, fn v ->
    String.length(v) in Map.keys(unique_lengths)
  end) end) |> Enum.sum
end

IO.puts("Part 1: #{calc_one.()}")


init_codemap = fn pats ->
  Enum.reduce(pats, %{}, fn s, lenmap ->
    u = Map.get(unique_lengths, length(s))
    if is_nil(u), do: lenmap, else: Map.put(lenmap, u, s)
  end)
end

group_by_seg = fn pats ->
  Enum.reduce(pats, %{}, fn s, found_seg ->
    Enum.reduce(s, found_seg, fn c, found_seg ->
      Map.update(found_seg, c, [s], &([s | &1]))
    end)
  end)
end

decode_values = fn %{pats: pats} ->
  garbled = init_codemap.(pats)  # values from unique_lengths
  segment_map =
    Enum.reduce(group_by_seg.(pats), %{}, fn {c, v}, segment_map ->
      case length(v) do
        8 -> if garbled[4] in v, do: "c", else: "a"
        7 -> if garbled[4] in v, do: "d", else: "g"
        n -> %{9 => "f", 6 => "b", 4 => "e"} |> Map.fetch!(n)
      end |> then(&Map.put(segment_map, &1, c))
    end)
  # values for all segments are now known
  Enum.reject(0..9, &Map.has_key?(garbled, &1)) |>
  Enum.reduce(garbled, fn d, garbled ->
    Enum.map(digits[d], &Map.fetch!(segment_map, &1)) |>
    then(&Map.put(garbled, d, Enum.sort(&1)))
  end) |> Map.new(fn {d, s} -> {Enum.join(s), d} end)
end

calc_two = fn ->
  Enum.map(data, fn d ->
    decoded = decode_values.(d)
    Enum.map_join(d.vals, &Map.fetch!(decoded, &1)) |> String.to_integer
  end) |> Enum.sum
end

IO.puts("Part 2: #{calc_two.()}")
