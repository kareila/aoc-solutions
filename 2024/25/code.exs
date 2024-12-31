# Solution to Advent of Code 2024, Day 25
# https://adventofcode.com/2024/day/25

Code.require_file("Matrix.ex", "..")
Code.require_file("Util.ex", "..")

# returns a list of GRIDS from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n\n") |>
  Enum.map(&String.split(&1, "\n", trim: true)) |>
  Enum.map(&Matrix.grid/1)
end

occupied = fn grid ->
  Matrix.map(grid) |> Util.group_tuples(1, 0) |>
  Map.fetch!("#") |> MapSet.new
end

parse_data = fn grids ->
  data = %{keys: MapSet.new, locks: MapSet.new}
  Enum.reduce(grids, data, fn grid, data ->
    if List.starts_with?(grid, [{0, 0, "#"}]) do
      %{data | keys: MapSet.put(data.keys, occupied.(grid))}
    else
      %{data | locks: MapSet.put(data.locks, occupied.(grid))}
    end
  end)
end

overlap_all = fn %{keys: keys, locks: locks} ->
  Task.async_stream(keys, fn key ->
    Enum.count(locks, fn lock ->
      collision = MapSet.intersection(lock, key)
      MapSet.size(collision) == 0
    end)
  end) |> Stream.map(fn {:ok, n} -> n end) |> Enum.sum
end

data = read_input.() |> parse_data.()
IO.puts("Part 1: #{overlap_all.(data)}")

# There is no Part 2!  Merry Christmas!
