# Solution to Advent of Code 2023, Day 6
# https://adventofcode.com/2023/day/6

Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_input = fn lines ->
  Enum.map(lines, &Util.read_numbers/1) |> Enum.zip
end

data = read_input.() |> parse_input.()

# find roots of equation x^2 - t*x + d = 0 and count integers in that range
# much faster than solution using simple counting of results (3-4 sec)

count_wins = fn {t, d} ->
  root1 = (0.5 * (t + (t ** 2 - 4 * d) ** 0.5)) |> floor
  root2 = (0.5 * (t - (t ** 2 - 4 * d) ** 0.5)) |> ceil
  Range.size(root1..root2)
end

IO.puts("Part 1: #{Enum.map(data, count_wins) |> Enum.product}")


list_to_int = fn list -> Enum.join(list) |> String.to_integer end

combine_nums = fn ->
  Enum.unzip(data) |> Tuple.to_list |> Enum.map(list_to_int) |> List.to_tuple
end

IO.puts("Part 2: #{combine_nums.() |> count_wins.()}")
