# Solution to Advent of Code 2022, Day 6
# https://adventofcode.com/2022/day/6

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# Input is single line of letters.
data = read_input.() |> hd |> String.graphemes

# Look for the first position where the
# preceding 4 characters were all different.
window = fn len ->
  Enum.reduce_while(len .. length(data), data, fn n, chars ->
    f = Enum.take(chars, len)
    if Enum.uniq(f) == f, do: {:halt, n}, else: {:cont, tl(chars)}
  end)
end

IO.puts("Part 1: #{window.(4)}")


# For the second part, use a window size of 14 instead of 4.
IO.puts("Part 2: #{window.(14)}")
