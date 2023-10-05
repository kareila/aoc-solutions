# Solution to Advent of Code 2020, Day 10
# https://adventofcode.com/2020/day/10

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

data = read_input.() |> Enum.map(&String.to_integer/1) |> Enum.sort

device = List.last(data) + 3
data = [0 | data] ++ [device]

pt1 =
  Enum.zip_with(tl(data), data, &-/2) |> Enum.frequencies |>
  Map.take([1, 3]) |> Map.values |> Enum.product

IO.puts("Part 1: #{pt1}")


pt2 =
  Enum.reduce(tl(data), %{0 => 1}, fn a, counts ->
    Map.take(counts, Range.to_list((a - 3)..(a - 1))) |>
    Map.values |> Enum.sum |> then(&Map.put(counts, a, &1))
  end) |> Map.fetch!(device)

IO.puts("Part 2: #{pt2}")
