# Solution to Advent of Code 2017, Day 3
# https://adventofcode.com/2017/day/3

Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# Taking the square's origin as {0,0}, every point at {1,1}, {2,2}, etc.
# is the square of the next odd integer (9, 25, 49...) so let's start by
# creating a list of those squares until we've reached our target number.
first_odd_square_after = fn num ->
  limit = :math.sqrt(num) |> ceil |> div(2) |> ceil
  Stream.iterate(1, &(&1 + 2)) |> Stream.map(&Integer.pow(&1, 2)) |>
  Stream.drop(limit) |> Enum.take(1) |> hd
end

# Once we have the value of the first square in that list greater
# than our target number, we know the length of the square's side
# at that point is the square root of that corner's number. Also,
# the grid coordinate of that corner point will be {n, n} such that
# the side's length is equal to 2n + 1.
find_coords = fn sq, num ->
  side = :math.sqrt(sq)|> trunc
  c = div(side - 1, 2)
  diff = sq - num
  cond do
    diff <  0 -> raise(RuntimeError)
    diff <= 2 * c -> {c - diff, c}       # { n, n} ... {-n, n}
    diff <= 4 * c -> {-c, 3 * c - diff}  # {-n, n} ... {-n,-n}
    diff <= 6 * c -> {diff - 5 * c, -c}  # {-n,-n} ... { n,-n}
    diff <  8 * c -> {c, diff - 7 * c}   # { n,-n} ... { n, n - 1}
    true -> raise(RuntimeError)
  end
end

steps = fn num ->
  first_odd_square_after.(num) |> find_coords.(num) |> Util.m_dist({0,0})
end

input = read_input.() |> hd |> String.to_integer

IO.puts("Part 1: #{steps.(input)}")


next_band = fn x ->
  Enum.map((x - 1)..-x//-1, &{x, &1}) ++
  Enum.map((x - 1)..-x//-1, &{&1, -x}) ++
  Enum.map((1 - x)..x, &{-x, &1}) ++
  Enum.map((1 - x)..x, &{&1, x})
end

adj_points = fn {x, y} ->
  for i <- (x - 1)..(x + 1), j <- (y - 1)..(y + 1), do: {i, j}
end

find_val = fn num ->
  init = %{ {0,0} => 1 }
  Enum.reduce_while(Stream.iterate(1, &(&1 + 1)), init, fn i, grid ->
    grid =
      Enum.reduce(next_band.(i), grid, fn p, grid ->
        v = Enum.map(adj_points.(p), &Map.get(grid, &1, 0)) |> Enum.sum
        Map.put(grid, p, v)
      end)
    if Map.fetch!(grid, {i, i}) <= num, do: {:cont, grid},
    else: {:halt, Map.values(grid) |> Enum.sort |> Enum.find(&(&1 > num))}
  end)
end

IO.puts("Part 2: #{find_val.(input)}")
