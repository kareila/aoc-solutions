# Solution to Advent of Code 2023, Day 21
# https://adventofcode.com/2023/day/21

Code.require_file("Matrix.ex", "..")
Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

lines = read_input.()
grid = Matrix.map(lines)
{x_min, x_max, y_min, y_max} = Matrix.limits(grid)
[origin] = Util.group_tuples(grid, 1, 0) |> Map.fetch!("S")

# We can do Part 1 using simple iteration, with a state reset every round.
step = fn _, list ->
  Enum.reduce(list, MapSet.new, fn pos, set ->
    Util.adj_pos(pos) |> Enum.filter(&(Map.get(grid, &1, "#") != "#")) |>
    MapSet.new |> MapSet.union(set)
  end)
end

reach_in = fn n -> Enum.reduce(1..n, [origin], step) |> MapSet.size end

IO.puts("Part 1: #{reach_in.(64)}")


# This is a general solution for Part 2, but it doesn't scale.
pt2 = %{origin: {origin, {0, 0}}}

adj_infinite = fn {pos, {ax, ay}} ->
  Enum.map(Util.adj_pos(pos), fn {i, j} ->
    cond do
      i < x_min -> {{x_max, j}, {ax - 1, ay}}
      i > x_max -> {{x_min, j}, {ax + 1, ay}}
      j < y_min -> {{i, y_max}, {ax, ay - 1}}
      j > y_max -> {{i, y_min}, {ax, ay + 1}}
      true -> {{i, j}, {ax, ay}}
    end
  end)
end

expand_edge = fn pos, visited ->
  Enum.reject(adj_infinite.(pos), fn {nxt, area} ->
    MapSet.member?(visited, {nxt, area}) or Map.fetch!(grid, nxt) == "#"
  end)
end

flood_fill = fn n ->
  Enum.reduce(1..n, {[pt2.origin], MapSet.new([pt2.origin])},
  fn _, {list, visited} ->
    edge = Enum.flat_map(list, &expand_edge.(&1, visited)) |> MapSet.new
    {edge, MapSet.union(edge, visited)}
  end) |> elem(1)
end

# This rest of this calculation relies on an assumption of
# the dimensions of the grid being odd numbers. If it were
# even, the position's second tuple values would be ignored.
reach_infinite = fn n ->
  flood_fill.(n) |> Enum.map(fn {{a, b}, {c, d}} -> [a, b, c, d] end) |>
  Enum.map(&Enum.sum/1) |> Enum.count(&(Integer.mod(&1, 2) == rem(n, 2)))
end

if rem(x_max, 2) != 0 or rem(y_max, 2) != 0,
do: raise(RuntimeError, "cannot proceed with given input")

# To scale this up to an extremely high number of steps, we have to
# leverage the mathematical properties of our given inputs. We can
# extrapolate a quadratic polynomial based on the values calculated
# at the edges of each of the first few grid repeats.
large_n = 26501365
poly_a = elem(origin, 0)
poly_b = Enum.count(lines)

if x_max != y_max or origin != {div(x_max, 2), div(y_max, 2)}
  or rem(large_n - poly_a, poly_b) != 0,
do: raise(RuntimeError, "cannot proceed with given input")

a0 = reach_infinite.(poly_a + poly_b * 0)
a1 = reach_infinite.(poly_a + poly_b * 1)
a2 = reach_infinite.(poly_a + poly_b * 2)

large_calc = fn n ->
  [b0, b1, b2] = [a0, a1 - a0, a2 - a1]
  b0 + b1 * n + div(n * (n-1), 2) * (b2 - b1)
end

IO.puts("Part 2: #{large_calc.(div(large_n - poly_a, poly_b))}")
