# Solution to Advent of Code 2018, Day 23
# https://adventofcode.com/2018/day/23

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

all_matches = fn str, pat ->
  Regex.scan(pat, str, capture: :all_but_first) |> Enum.concat
end

parse_line = fn line ->
  [loc, _, radius] = all_matches.(line, ~r/([-0-9,]+)/)
  pos = String.split(loc, ",") |> Enum.map(&String.to_integer/1)
  {List.to_tuple(pos), String.to_integer(radius)}
end

data = read_input.() |> Enum.map(parse_line)
coords = Enum.map(data, &elem(&1,0))

# calculate the Manhattan distance between 3D points
m_dist3 = fn {x1, y1, z1}, {x2, y2, z2} ->
  abs( x1 - x2 ) + abs( y1 - y2 ) + abs( z1 - z2 )
end

in_largest_range = fn ->
  {origin, range} = List.keysort(data, 1) |> List.last
  Enum.count(coords, fn pos -> m_dist3.(pos, origin) <= range end)
end

IO.puts("Part 1: #{in_largest_range.()}")


# For Part 2, my first thought was to calculate the set of points in
# range of each bot and compute the overlaps, but even on the simple
# test case it was immediately clear that would take too long, so I
# next considered a divide-and-conquer strategy with bounding boxes.

init_bounds = fn ->
  {x_min, x_max} = Enum.map(coords, &elem(&1,0)) |> Enum.min_max
  {y_min, y_max} = Enum.map(coords, &elem(&1,1)) |> Enum.min_max
  {z_min, z_max} = Enum.map(coords, &elem(&1,2)) |> Enum.min_max
  # round the differences up to the nearest power of two
  maxlen = Enum.max([x_max - x_min, y_max - y_min, z_max - z_min])
  side = Stream.iterate(1, &(&1 * 2)) |>
         Stream.drop_while(&(&1 < maxlen)) |> Enum.at(0)
  %{min: {x_min, y_min, z_min}, side: side,
    max: {x_min + side, y_min + side, z_min + side}}
end

divide_cube = fn %{min: {x1, y1, z1}, max: {x2, y2, z2}, side: side} ->
  side = div(side, 2)
  for {x_min, x_max} <- [{x1, x1 + side}, {x1 + side + 1, x2}],
      {y_min, y_max} <- [{y1, y1 + side}, {y1 + side + 1, y2}],
      {z_min, z_max} <- [{z1, z1 + side}, {z1 + side + 1, z2}],
  do: %{min: {x_min, y_min, z_min}, max: {x_max, y_max, z_max}, side: side}
end

# Figuring out the most appropriate formula for representing the distance
# between a box and a bot was the most troublesome part of this exercise.
# We can't just use the Manhattan distance formula because a coordinate's
# distance only counts if it's outside the box, not contained inside.
dist_from_box = fn {x, y, z}, %{min: {x1, y1, z1}, max: {x2, y2, z2}} ->
  [x - x2, x1 - x, y - y2, y1 - y, z - z2, z1 - z] |>
  Enum.filter(&(&1 > 0)) |> Enum.sum
end

# We count how many are OUT of range to keep all the sorts in order.
out_of_range = fn box ->
  Enum.count(data, fn {pos, r} -> dist_from_box.(pos, box) > r end)
end

dist_to_origin = fn box -> m_dist3.(box.min, {0,0,0}) end

index_box = fn box ->
  {out_of_range.(box), dist_to_origin.(box), box.side, box}
end

find_max = fn ->
  init_queue = init_bounds.() |> index_box.() |> List.wrap
  Enum.reduce_while(Stream.cycle([1]), init_queue, fn _, queue ->
    [{_, dist, sz, box} | queue] = queue
    if sz == 0, do: {:halt, dist},
    else: {:cont, divide_cube.(box) |> Enum.map(index_box) |>
      Enum.concat(queue) |> Enum.sort}
  end)
end

IO.puts("Part 2: #{find_max.()}")
