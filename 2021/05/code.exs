# Solution to Advent of Code 2021, Day 5
# https://adventofcode.com/2021/day/5

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

all_matches = fn str, pat ->
  Regex.scan(pat, str, capture: :all_but_first) |> Enum.concat
end

read_numbers = fn str ->
  all_matches.(str, ~r/(\d+)/) |> Enum.map(&String.to_integer/1)
end

data = read_input.() |> Enum.map(read_numbers)

# I think the key insight here is that for each range of points, X and
# Y both will always either (a) change by one, or (b) stay the same.

line_points = fn [x1, y1, x2, y2] ->
  cond do
    x1 == x2 -> Enum.map(y1..y2, &({x1, &1}))
    y1 == y2 -> Enum.map(x1..x2, &({&1, y1}))
    true -> Enum.zip(x1..x2, y1..y2)
  end
end

update_maps = fn pos, {mapped, overlaps} ->
  if MapSet.member?(mapped, pos), do: {mapped, MapSet.put(overlaps, pos)},
  else: {MapSet.put(mapped, pos), overlaps}
end

calc_one = fn ->
  Enum.reduce(data, {MapSet.new, MapSet.new},
  fn [x1, y1, x2, y2], map_data ->
    if x1 == x2 or y1 == y2,
    do: Enum.reduce(line_points.([x1, y1, x2, y2]), map_data, update_maps),
    else: map_data
  end) |> elem(1) |> MapSet.size
end

IO.puts("Part 1: #{calc_one.()}")


calc_two = fn ->
  Enum.reduce(data, {MapSet.new, MapSet.new}, fn line, map_data ->
    Enum.reduce(line_points.(line), map_data, update_maps)
  end) |> elem(1) |> MapSet.size
end

IO.puts("Part 2: #{calc_two.()}")
