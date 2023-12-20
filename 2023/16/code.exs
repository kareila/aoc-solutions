# Solution to Advent of Code 2023, Day 16
# https://adventofcode.com/2023/day/16

Code.require_file("Matrix.ex", "..")
Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

grid = read_input.() |> Matrix.map

init_data = fn start -> %{beam: [start], energized: MapSet.new} end

next_step = fn {x, y, dir} ->
  Util.dir_pos({x, y}) |> Map.fetch!(dir) |> Tuple.append(dir)
end

step_beam = fn data ->
  [{x, y, dir} = pos | beam] = data.beam
  data = %{data | energized: MapSet.put(data.energized, pos)}
  nxt =
    case {Map.fetch!(grid, {x, y}), dir} do
      {".", dir} -> [dir]
      {"/", "N"} -> ["E"]
      {"/", "W"} -> ["S"]
      {"/", "S"} -> ["W"]
      {"/", "E"} -> ["N"]
      {"\\", "N"} -> ["W"]
      {"\\", "W"} -> ["N"]
      {"\\", "S"} -> ["E"]
      {"\\", "E"} -> ["S"]
      {"|", dir} when dir in ~w(N S)s -> [dir]
      {"-", dir} when dir in ~w(W E)s -> [dir]
      {"-", dir} when dir in ~w(N S)s -> ~w(W E)s
      {"|", dir} when dir in ~w(W E)s -> ~w(N S)s
    end |> Enum.map(fn d -> next_step.({x, y, d}) end)
        |> Enum.filter(fn {i, j, _} -> Map.has_key?(grid, {i, j}) end)
        |> Enum.reject(&MapSet.member?(data.energized, &1))
  %{data | beam: nxt ++ beam}  # DFS is slightly faster than BFS here
end

map_beam = fn data ->
  Enum.reduce_while(Stream.cycle([1]), data, fn _, data ->
    if Enum.empty?(data.beam), do: {:halt, data.energized},
    else: {:cont, step_beam.(data)}
  end)
end

num_energized = fn set ->
  Enum.uniq_by(set, fn {x, y, _} -> {x, y} end) |> length
end

pt1 = init_data.({0, 0, "E"}) |> map_beam.()

IO.puts("Part 1: #{num_energized.(pt1)}")


start_points = fn ->
  {_, x_max, _, y_max} = Matrix.limits(grid)
  Enum.flat_map(0..x_max, fn x -> [{x, 0, "S"}, {x, y_max, "N"}] end) ++
  Enum.flat_map(0..y_max, fn y -> [{0, y, "E"}, {x_max, y, "W"}] end)
end

do_tasks = fn beams ->
  for {:ok, v} <- Task.async_stream(beams, map_beam), do: num_energized.(v)
end

pt2 = start_points.() |> Enum.map(init_data) |> do_tasks.()

IO.puts("Part 2: #{Enum.max(pt2)}")

# elapsed time: approx. 1.5 sec for both parts together
