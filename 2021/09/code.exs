# Solution to Advent of Code 2021, Day 9
# https://adventofcode.com/2021/day/9

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

matrix = fn lines ->
  for {line, y} <- Enum.with_index(lines),
      {v, x} <- String.graphemes(line) |> Enum.with_index,
  do: {x, y, String.to_integer(v)}
end

matrix_map = fn matrix ->
  for {x, y, v} <- matrix, into: %{}, do: { {x, y}, v }
end

grid = read_input.() |> matrix.()
data = matrix_map.(grid)

# default value of 9 is not lower than anything
point_value = fn pos -> Map.get(data, pos, 9) end

adj_pos = fn {x, y} ->
  [{x - 1, y}, {x + 1, y}, {x, y - 1}, {x, y + 1}]
end

is_low_point? = fn {x, y, v} ->
  Enum.all?(adj_pos.({x, y}), fn p -> point_value.(p) > v end)
end

low_points = Enum.filter(grid, is_low_point?)

total_risk = fn ->
  Enum.map(low_points, fn {_, _, v} -> v + 1 end) |> Enum.sum
end

IO.puts("Part 1: #{total_risk.()}")


size_basin = fn {px, py, _} ->
  Enum.reduce_while(Stream.cycle([1]), {[{px, py}], MapSet.new([{px, py}])},
  fn _, {queue, visited} ->
    if Enum.empty?(queue) do {:halt, MapSet.size(visited)}
    else
      [pos | queue] = queue
      Enum.reduce(adj_pos.(pos), {queue, visited}, fn p, {queue, visited} ->
        if point_value.(p) == 9 or MapSet.member?(visited, p) do
          {queue, visited}
        else
          {[p | queue], MapSet.put(visited, p)}
        end
      end) |> then(&({:cont, &1}))
    end
  end)
end

top_three = fn ->
  Enum.map(low_points, size_basin) |> Enum.sort(:desc) |>
  Enum.take(3) |> Enum.product
end

IO.puts("Part 2: #{top_three.()}")
