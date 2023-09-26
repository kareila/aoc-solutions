# Solution to Advent of Code 2017, Day 22
# https://adventofcode.com/2017/day/22

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# parses input as a grid of values
matrix = fn lines ->
  for {line, y} <- Enum.with_index(lines),
      {v, x} <- String.graphemes(line) |> Enum.with_index,
  do: {x, y, v}
end

matrix_map = fn matrix ->
  for {x, y, v} <- matrix, into: %{}, do: { {x, y}, v }
end

min_max_i = fn matrix -> Enum.map(matrix, &elem(&1,1)) |> Enum.min_max end

parse_input = fn input ->
  grid = matrix.(input)
  i_max = elem(min_max_i.(grid), 1)  # the grid is a square
  i = div(i_max, 2)  # we don't have to start at {0,0}
  %{grid: matrix_map.(grid), dir: "N", pos: {i, i}, infections: 0}
end

init_data = read_input.() |> parse_input.()

turn_left = fn dir ->
  Map.fetch!(%{"N" => "W", "W" => "S", "S" => "E", "E" => "N"}, dir)
end

turn_right = fn dir ->
  Map.fetch!(%{"N" => "E", "E" => "S", "S" => "W", "W" => "N"}, dir)
end

adj_pos = fn {x, y} -> [{x - 1, y}, {x + 1, y}, {x, y - 1}, {x, y + 1}] end
dir_pos = fn pos -> Enum.zip(~w(W E N S), adj_pos.(pos)) |> Map.new end

step = fn data, turns, state ->
  loc = Map.get(data.grid, data.pos, ".")
  dir = Map.fetch!(turns, loc).(data.dir)
  loc = Map.fetch!(state, loc)
  inf = data.infections + if loc == "#", do: 1, else: 0
  %{dir: dir, pos: dir_pos.(data.pos) |> Map.fetch!(dir),
    infections: inf, grid: Map.put(data.grid, data.pos, loc)}
end

turns_pt1 = %{"#" => turn_right, "." => turn_left}
state_pt1 = %{"#" => ".", "." => "#"}
step1 = fn data -> step.(data, turns_pt1, state_pt1) end

count_infected = fn data -> data.infections end

do_repeat = fn data, step, n ->
  Enum.reduce(1..n, data, fn _, data -> step.(data) end) |> count_infected.()
end

IO.puts("Part 1: #{do_repeat.(init_data, step1, 10_000)}")


# same thing with twice as many states
turn_180 = fn dir ->
  Map.fetch!(%{"N" => "S", "S" => "N", "E" => "W", "W" => "E"}, dir)
end

turn_360 = fn dir -> dir end

turns_pt2 = Map.merge(turns_pt1, %{"W" => turn_360, "F" => turn_180})
state_pt2 = %{"F" => ".", "." => "W", "W" => "#", "#" => "F"}
step2 = fn data -> step.(data, turns_pt2, state_pt2) end

IO.puts("Part 2: #{do_repeat.(init_data, step2, 10_000_000)}")

# elapsed time: approx. 5 sec for both parts together
