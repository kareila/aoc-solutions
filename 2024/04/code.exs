# Solution to Advent of Code 2024, Day 4
# https://adventofcode.com/2024/day/4

Code.require_file("Matrix.ex", "..")
Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

data = read_input.() |> Matrix.grid
puzzle = Matrix.map(data)
letters = Util.group_tuples(data, 2)


# turn a list of positions into a string
p_vals = fn list -> Enum.map_join(list, &Map.get(puzzle, &1, "")) end

# extend a given direction to cover two more positions
draw_line = fn a, b ->
  List.duplicate(b - a, 3) |> Enum.zip_with(1..3, &*/2) |>
  Enum.zip_with(List.duplicate(a, 3), &+/2)
end

# for each starting X, check all eight possible directions
get_x_strs = fn {x, y, _} ->
  Enum.map(Util.sur_pos({x, y}), fn {i, j} ->
    [{x, y} | Enum.zip(draw_line.(x, i), draw_line.(y, j))] |> p_vals.()
  end)
end

# see how many of the possibilities match what we are looking for
count_matches = fn list, ok -> Enum.count(list, & &1 in ok) end

x_points = Map.fetch!(letters, "X")
find_xmas = fn s -> count_matches.(s, ["XMAS"]) end

IO.puts("Part 1: #{Enum.flat_map(x_points, get_x_strs) |> find_xmas.()}")

# for Part 2, fewer points to check, but make sure order is clockwise
get_a_str = fn {x, y, _} ->
  p_vals.([{x - 1, y - 1}, {x + 1, y - 1}, {x + 1, y + 1}, {x - 1, y + 1}])
end

a_points = Map.fetch!(letters, "A")
find_mas = fn s -> count_matches.(s, ["MMSS", "SMMS", "SSMM", "MSSM"]) end

IO.puts("Part 2: #{Enum.map(a_points, get_a_str) |> find_mas.()}")
