# Solution to Advent of Code 2024, Day 1
# https://adventofcode.com/2024/day/1

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# split each string into a pair of integers
parse_line = fn s -> String.split(s) |> Enum.map(&String.to_integer/1) end

# transpose rows and columns
merge_lines = fn list -> Enum.zip(list) |> Enum.map(&Tuple.to_list/1) end

# sort the values of each column before continuing
data = read_input.() |> Enum.map(parse_line) |>
       merge_lines.() |> Enum.map(&Enum.sort/1)


# Part 1: find the differences between each pair
difference = fn [a, b] -> abs(a - b) end

IO.puts("Part 1: #{Enum.zip_with(data, difference) |> Enum.sum}")

# Part 2: calculate the similarity score
similarity = fn [a_list, b_list] ->
  freq = Enum.frequencies(b_list)
  Enum.map(a_list, &Map.get(freq, &1, 0)) |> Enum.zip_with(a_list, &*/2)
end

IO.puts("Part 2: #{similarity.(data) |> Enum.sum}")
