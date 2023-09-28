# Solution to Advent of Code 2018, Day 6
# https://adventofcode.com/2018/day/6

Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_line = fn line -> Util.read_numbers(line) |> List.to_tuple end

data = read_input.() |> Enum.map(parse_line)

{x_min, x_max} = Enum.map(data, &elem(&1,0)) |> Enum.min_max
{y_min, y_max} = Enum.map(data, &elem(&1,1)) |> Enum.min_max

grid = for i <- x_min .. x_max, j <- y_min .. y_max, do: {i, j}

find_closest = fn pos ->
  dist = Enum.map(data, fn c -> {c, Util.m_dist(c, pos)} end)
  dmin = Enum.min_by(dist, fn {_, v} -> v end) |> elem(1)
  locs = Enum.flat_map(dist, fn {k, v} -> if v == dmin, do: [k], else: [] end)
  {pos, locs}
end

closest = Map.new(grid, find_closest) |>
          Map.reject(fn {_, v} -> length(v) > 1 end)

find_finite = fn ->
  edges =
    Enum.filter(grid, fn {i, j} ->
      i in [x_min, x_max] or j in [y_min, y_max]
    end) |> Enum.flat_map(&Map.get(closest, &1, []))
  data -- edges
end

area = fn pos ->
  Enum.filter(closest, fn {_, v} -> v == [pos] end) |> length
end

largest_area_size = find_finite.() |> Enum.map(area) |> Enum.max

IO.puts("Part 1: #{largest_area_size}")


find_totals = fn pos ->
  Enum.map(data, fn c -> Util.m_dist(c, pos) end) |> Enum.sum
end

nearest_area_size =
  Enum.map(grid, find_totals) |> Enum.count(&(&1 < 10000))

IO.puts("Part 2: #{nearest_area_size}")
