# Solution to Advent of Code 2017, Day 4
# https://adventofcode.com/2017/day/4

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

is_valid? = fn phrase -> length(phrase) == length(Enum.uniq(phrase)) end

data = read_input.() |> Enum.map(&String.split/1)

IO.puts("Part 1: #{Enum.count(data, is_valid?)}")


sort_words = fn phrase ->
  Enum.map(phrase, fn word ->
    String.graphemes(word) |> Enum.sort |> Enum.join
  end)
end

data = Enum.map(data, sort_words)

IO.puts("Part 2: #{Enum.count(data, is_valid?)}")
