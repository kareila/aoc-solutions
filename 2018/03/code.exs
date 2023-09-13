# Solution to Advent of Code 2018, Day 3
# https://adventofcode.com/2018/day/3

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_line = fn line ->
  Regex.run(~r/(\d+) @ (\d+),(\d+): (\d+)x(\d+)$/, line)
  |> tl |> Enum.map(&String.to_integer/1)
end

data = read_input.() |> Enum.map(parse_line)

list_points = fn [_id, x_orig, y_orig, x_len, y_len] ->
  for i <- 1..x_len, j <- 1..y_len, into: [],
  do: {x_orig + i - 1, y_orig + j - 1}
end

overlaps = Enum.flat_map(data, list_points) |> Enum.frequencies

count_overlaps = Map.values(overlaps) |> Enum.count(fn n -> n > 1 end)

IO.puts("Part 1: #{count_overlaps}")


find_candidate =
  Enum.reduce_while(data, nil, fn [id | _] = claim, _ ->
    if Enum.all?(list_points.(claim), &(overlaps[&1] == 1)),
    do: {:halt, id}, else: {:cont, nil}
  end)

IO.puts("Part 2: #{find_candidate}")
