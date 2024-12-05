# Solution to Advent of Code 2024, Day 2
# https://adventofcode.com/2024/day/2

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# split each string into integers
parse_line = fn s -> String.split(s) |> Enum.map(&String.to_integer/1) end

data = Enum.map(read_input.(), parse_line)


# track the differences between adjacent numbers
line_diffs = fn line -> Enum.zip_with(line, tl(line), &-/2) end

# are levels all increasing or decreasing?
is_monotonic? = fn diffs ->
  Enum.all?(diffs, & &1 > 0) or Enum.all?(diffs, & &1 < 0)
end

# is each difference within the allowed range?
is_tolerable? = fn diffs ->
  abs_diffs = Enum.map(diffs, &abs/1)
  Enum.all?(abs_diffs, & &1 > 0) and Enum.all?(abs_diffs, & &1 < 4)
end

count_safe = fn d -> Enum.count(d, & &1 != []) end

# filter out any lines that don't pass the test
check_lines = fn d ->
  Enum.map(d, line_diffs) |>
  Enum.filter(is_monotonic?) |> Enum.filter(is_tolerable?)
end

IO.puts("Part 1: #{check_lines.(data) |> count_safe.()}")

# see if removing a single element will cause tests to pass
dampen_data = fn line ->
  Enum.map(1..length(line), &List.delete_at(line, &1 - 1))
end

data = Enum.map(data, dampen_data)

IO.puts("Part 2: #{Enum.map(data, check_lines) |> count_safe.()}")
