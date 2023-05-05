# Solution to Advent of Code 2022, Day 3
# https://adventofcode.com/2022/day/3

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# Calculate the "priority" value of a character.
rank = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
  |> String.graphemes
priority = fn c -> Enum.find_index(rank, &(&1 == c)) + 1 end

# Find the single character that appears in each given string.
find_common = fn strings ->
  [first | rest] = Enum.map(strings, &String.graphemes/1)
  # Using reduce_while for flow control, not accumulation.
  Enum.reduce_while(first, nil, fn c, _ ->
    if Enum.all?(rest, &Enum.member?(&1, c)),
    do: {:halt, priority.(c)}, else: {:cont, nil}
  end)
end

common_sum = fn set, total -> total + find_common.(set) end

halves = fn line ->  # these are all equally divisible by two
  String.split_at(line, String.length(line) |> div(2)) |> Tuple.to_list
end

data = read_input.()
total = Enum.map(data, halves) |> Enum.reduce(0, common_sum)

IO.puts("Part 1: #{total}")


# For the second part, instead of comparing two halves of one line,
# we are comparing each group of three lines to find the item in common.

total = Enum.chunk_every(data, 3) |> Enum.reduce(0, common_sum)

IO.puts("Part 2: #{total}")
