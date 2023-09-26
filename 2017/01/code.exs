# Solution to Advent of Code 2017, Day 1
# https://adventofcode.com/2017/day/1

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_line = fn line ->
  Integer.parse(line, 10) |> elem(0) |> Integer.digits
end

find_matches = fn list ->
  Enum.flat_map(list, fn {a, b} -> if a == b, do: [a], else: [] end)
end

find_matches_next = fn list ->
  [List.last(list) | list] |> Enum.zip(list) |> find_matches.() |> Enum.sum
end

data = read_input.() |> hd |> parse_line.()

IO.puts("Part 1: #{find_matches_next.(data)}")


find_matches_halfway = fn list ->
  {first, last} = Enum.split(list, div(length(list), 2))
  Enum.zip(first, last) |> find_matches.() |> Enum.sum |> then(&(&1 * 2))
end

IO.puts("Part 2: #{find_matches_halfway.(data)}")
