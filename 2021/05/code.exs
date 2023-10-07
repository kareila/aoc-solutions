# Solution to Advent of Code 2021, Day 5
# https://adventofcode.com/2021/day/5

Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

data = read_input.() |> Enum.map(&Util.read_numbers/1)

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

count_overlaps = fn keep ->
  Enum.reduce(data, {MapSet.new, MapSet.new}, fn line, map_data ->
    if not keep.(line), do: map_data,
    else: Enum.reduce(line_points.(line), map_data, update_maps)
  end) |> elem(1) |> MapSet.size
end

no_diagonals = fn [x1, y1, x2, y2] -> x1 == x2 or y1 == y2 end

IO.puts("Part 1: #{count_overlaps.(no_diagonals)}")
IO.puts("Part 2: #{count_overlaps.(fn _ -> true end)}")
