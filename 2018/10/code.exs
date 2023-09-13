# Solution to Advent of Code 2018, Day 10
# https://adventofcode.com/2018/day/10

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

matrix_map = fn matrix ->
  for {x, y, v} <- matrix, into: %{}, do: { {x, y}, v }
end

min_max_x = fn matrix -> Enum.map(matrix, &elem(&1,0)) |> Enum.min_max end
min_max_y = fn matrix -> Enum.map(matrix, &elem(&1,1)) |> Enum.min_max end

all_matches = fn str, pat ->
  Regex.scan(pat, str, capture: :all_but_first) |> Enum.concat
end

parse_line = fn line ->
  [px, py, vx, vy] = all_matches.(line, ~r/<([^,]+), ([^>]+)/)
    |> Enum.map(&String.to_integer(String.trim(&1)))
  {px, py, {vx, vy}}
end

parse_lines = fn lines -> Enum.map(lines, parse_line) end

tick = fn grid ->
  Enum.map(grid, fn {px, py, {vx, vy}} -> {px + vx, py + vy, {vx, vy}} end)
end

find_limits = fn grid ->
  [min_max_x.(grid), min_max_y.(grid)]
   |> Enum.map(&Tuple.to_list/1) |> List.flatten
end

has_neighbor? = fn {x, y, _}, data ->
  Enum.count([{x - 1, y}, {x + 1, y}, {x, y - 1}, {x, y + 1}], fn {i, j} ->
    Map.has_key?(data, {i, j})
  end) > 0
end

find_message = fn grid ->
  num = Enum.count(grid)
  Enum.reduce_while(Stream.iterate(1, &(&1 + 1)), grid, fn t, prev ->
    next = tick.(prev)
    data = matrix_map.(next)
    adj = Enum.filter(next, &has_neighbor?.(&1, data)) |> Enum.count
    if num - adj < div(num, 10), do: {:halt, {t, next}}, else: {:cont, next}
  end)
end

print_grid = fn grid ->
  [xmin, xmax, ymin, ymax] = find_limits.(grid)
  data = matrix_map.(grid)
  Enum.map_join(ymin..ymax, "\n", fn j ->
    Enum.map_join(xmin..xmax, fn i ->
      if Map.has_key?(data, {i, j}), do: "#", else: "."
    end)
  end)
end

{secs, grid} = read_input.() |> parse_lines.() |> find_message.()

IO.puts("Part 1: \n#{print_grid.(grid)}")
IO.puts("Part 2: #{secs}")

# elapsed time: approx. 1.5 sec
