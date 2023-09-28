# Solution to Advent of Code 2019, Day 3
# https://adventofcode.com/2019/day/3

Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_interval = fn str, {pos_x, pos_y} ->
  {dir, dist} = String.split_at(str, 1)
  dist = String.to_integer(dist)
  case dir do
    "R" -> for i <- 1..dist, do: {pos_x + i, pos_y}
    "L" -> for i <- 1..dist, do: {pos_x - i, pos_y}
    "U" -> for j <- 1..dist, do: {pos_x, pos_y + j}
    "D" -> for j <- 1..dist, do: {pos_x, pos_y - j}
  end
end

get_steps = fn line ->
  String.split(line, ",") |>
  Enum.reduce([{0,0}], fn val, pts ->
    pos = Enum.at(pts, -1)
    pts ++ parse_interval.(val, pos)
  end)
end

get_intersections = fn pair ->
  get_points = fn steps -> tl(steps) |> MapSet.new end
  [set1, set2] = Enum.map(pair, get_points)
  MapSet.intersection(set1, set2)
end

min_dist = fn set ->
  Enum.map(set, fn pos -> Util.m_dist(pos, {0,0}) end) |> Enum.min
end

steps = read_input.() |> Enum.map(get_steps)
intersect = get_intersections.(steps)

IO.puts("Part 1: #{min_dist.(intersect)}")


num_steps = fn pos, pair ->
  count_steps = fn steps -> Enum.find_index(steps, &(&1 == pos)) end
  Enum.map(pair, count_steps) |> Enum.sum
end

min_steps = fn steps, set ->
  Enum.map(set, fn pos -> num_steps.(pos, steps) end) |> Enum.min
end

IO.puts("Part 2: #{min_steps.(steps, intersect)}")
