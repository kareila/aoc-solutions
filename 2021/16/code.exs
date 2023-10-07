# Solution to Advent of Code 2021, Day 16
# https://adventofcode.com/2021/day/16

Code.require_file("Util.ex", "..")
Code.require_file("Recurse.ex", ".")  # for decode_packet()

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_input = fn line ->
  Enum.map_join(String.graphemes(line), &Util.hex_digit_to_binary/1)
end

info = read_input.() |> hd |> parse_input.() |> Recurse.decode_packet()

IO.puts("Part 1: #{info.version_sum}")
IO.puts("Part 2: #{info.value}")
