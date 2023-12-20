# Solution to Advent of Code 2023, Day 18
# https://adventofcode.com/2023/day/18

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_line = fn line ->
  [dir, dist, color] = String.split(line)
  %{dir: dir, dist: String.to_integer(dist), color: color}
end

parse_color = fn %{color: color} ->
  {c, [d]} = String.graphemes(color) |> Enum.slice(2..7) |> Enum.split(-1)
  dir = %{"0" => "R", "1" => "D", "2" => "L", "3" => "U"} |> Map.fetch!(d)
  {dist, _} = Enum.join(c) |> Integer.parse(16)
  %{dir: dir, dist: dist}
end

pt1 = read_input.() |> Enum.map(parse_line)
pt2 = Enum.map(pt1, parse_color)

# https://en.wikipedia.org/wiki/Shoelace_formula
shoelace_solve = fn rules ->
  dirs = %{"U" => {0, -1}, "D" => {0, 1}, "L" => {-1, 0}, "R" => {1, 0}}
  r = Enum.reduce(rules, %{x: 0, y: 0, area: 0, loop: 1},
    fn %{dir: dir, dist: dist}, %{x: x, y: y, area: area, loop: loop} ->
      {dx, dy} = Map.fetch!(dirs, dir)
      {nx, ny} = {x + dist * dx, y + dist * dy}
      area = area + (y * nx - x * ny)
      %{x: nx, y: ny, area: area, loop: loop + (dist / 2)}
    end)
  trunc(abs(r.area / 2) + r.loop)
end

IO.puts("Part 1: #{shoelace_solve.(pt1)}")
IO.puts("Part 2: #{shoelace_solve.(pt2)}")
