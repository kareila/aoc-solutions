# Solution to Advent of Code 2024, Day 11
# https://adventofcode.com/2024/day/11

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# count how many times each stone appears in the field
parse_line = fn [line] ->
  String.split(line) |> Enum.map(&String.to_integer/1) |> Enum.frequencies
end

stones = read_input.() |> parse_line.()


# apply the rules to a single stone
blink_stone = fn n ->
  d = Integer.digits(n)
  {len, mod} = {div(length(d), 2), Integer.mod(length(d), 2)}
  cond do
    n == 0 -> [1]
    mod == 0 -> Enum.chunk_every(d, len) |> Enum.map(&Integer.undigits/1)
    true -> [n * 2024]
  end
end

# apply the rules to all stones in the field, once per value
# (key insights: values tend to recur and list ordering doesn't matter)
blink_map = fn _, field ->
  Enum.reduce(field, %{}, fn {n, q}, data ->
    blink_stone.(n) |>
    Enum.reduce(data, fn s, d -> Map.update(d, s, q, & &1 + q) end)
  end)
end

repeat_blink = fn data, t ->
  Enum.reduce(1..t, data, blink_map) |> Map.values |> Enum.sum
end

IO.puts("Part 1: #{repeat_blink.(stones, 25)}")
IO.puts("Part 2: #{repeat_blink.(stones, 75)}")
