# Solution to Advent of Code 2021, Day 9
# https://adventofcode.com/2021/day/9

Code.require_file("Matrix.ex", "..")
Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

int_vals = fn {x, y, v} -> {x, y, String.to_integer(v)} end

grid = read_input.() |> Matrix.grid |> Enum.map(int_vals)
data = Matrix.map(grid)

# default value of 9 is not lower than anything
point_value = fn pos -> Map.get(data, pos, 9) end

is_low_point? = fn {x, y, v} ->
  Enum.all?(Util.adj_pos({x, y}), fn p -> point_value.(p) > v end)
end

low_points = Enum.filter(grid, is_low_point?)

total_risk = fn ->
  Enum.map(low_points, fn {_, _, v} -> v + 1 end) |> Enum.sum
end

IO.puts("Part 1: #{total_risk.()}")


visit_pos = fn p, {queue, visited} ->
  if point_value.(p) == 9 or p in visited, do: {queue, visited},
  else: {[p | queue], [p | visited]}
end

size_basin = fn {px, py, _} ->
  Enum.reduce_while(Stream.cycle([1]), {[{px, py}], [{px, py}]},
  fn _, {queue, visited} ->
    if Enum.empty?(queue) do {:halt, length(visited)}
    else
      [pos | queue] = queue
      {:cont, Enum.reduce(Util.adj_pos(pos), {queue, visited}, visit_pos)}
    end
  end)
end

top_three = fn ->
  Enum.map(low_points, size_basin) |> Enum.sort(:desc) |>
  Enum.take(3) |> Enum.product
end

IO.puts("Part 2: #{top_three.()}")
