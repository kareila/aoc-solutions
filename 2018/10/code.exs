# Solution to Advent of Code 2018, Day 10
# https://adventofcode.com/2018/day/10

Code.require_file("Matrix.ex", "..")
Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_line = fn line ->
  [px, py, vx, vy] = Util.read_numbers(line)
  {px, py, {vx, vy}}
end

tick = fn grid ->
  Enum.map(grid, fn {px, py, {vx, vy}} -> {px + vx, py + vy, {vx, vy}} end)
end

has_neighbor? = fn {x, y, _}, data ->
  Util.adj_pos({x, y}) |> Enum.any?(&Map.has_key?(data, &1))
end

find_message = fn grid ->
  num = Enum.count(grid)
  Enum.reduce_while(Stream.iterate(1, &(&1 + 1)), grid, fn t, prev ->
    next = tick.(prev)
    data = Matrix.map(next)
    adj = Enum.count(next, &has_neighbor?.(&1, data))
    if num - adj < div(num, 10), do: {:halt, {t, data}}, else: {:cont, next}
  end)
end

print_grid = fn data ->
  Map.keys(data) |> Map.from_keys("#") |> Matrix.print_sparse_map
end

{secs, grid} = read_input.() |> Enum.map(parse_line) |> find_message.()

IO.puts("Part 1: \n#{print_grid.(grid)}")
IO.puts("Part 2: #{secs}")

# elapsed time: approx. 1.5 sec
