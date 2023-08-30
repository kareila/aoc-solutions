# Solution to Advent of Code 2019, Day 8
# https://adventofcode.com/2019/day/8

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_input = fn line, x, y ->
  # each layer is x pixels wide and y pixels tall
  String.graphemes(line) |> Enum.chunk_every(x * y)
end

find_min_zeroes = fn data ->
  Enum.map(data, &Enum.frequencies/1) |> Enum.min_by(fn d -> d["0"] end)
end

layers = read_input.() |> hd |> parse_input.(25, 6)
z_layer = find_min_zeroes.(layers)

IO.puts("Part 1: #{z_layer["1"] * z_layer["2"]}")


decode_image = fn data ->
  Enum.reverse(data) |>
  Enum.reduce(fn layer, image ->
    Enum.zip(layer, image) |>
    Enum.map(fn {l, i} -> if l == "2", do: i, else: l end)
  end)
end

display_image = fn data, x ->
  Enum.chunk_every(data, x) |> Enum.map_join("\n", &Enum.join/1) |>
  String.replace("0", " ") |> String.replace("1", "X")
end

IO.puts("Part 2: \n#{decode_image.(layers) |> display_image.(25)}")
