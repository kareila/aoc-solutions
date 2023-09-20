# Solution to Advent of Code 2021, Day 16
# https://adventofcode.com/2021/day/16

require Recurse  # for decode_packet()

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# Make sure to parse each individual character into a 4 digit
# binary value, instead of parsing the entire number as a whole.
parse_digit = fn c ->
  Integer.parse(c, 16) |> elem(0) |> # decimal value of hex digit
  Integer.digits(2) |> Enum.join |>  # binary value as string
  String.pad_leading(4, "0")         # fixed width of 4 bits
end

parse_input = fn line ->
  Enum.map_join(String.graphemes(line), parse_digit)
end

info = read_input.() |> hd |> parse_input.() |> Recurse.decode_packet()

IO.puts("Part 1: #{info.version_sum}")
IO.puts("Part 2: #{info.value}")
