# Solution to Advent of Code 2019, Day 10
# https://adventofcode.com/2019/day/10

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# parses input as a grid of values
matrix = fn lines ->
  for {line, y} <- Enum.with_index(lines),
      {v, x} <- String.graphemes(line) |> Enum.with_index,
  do: {x, y, v}
end

matrix_map = fn matrix ->
  for {x, y, v} <- matrix, into: %{}, do: { {x, y}, v }
end

# calculate the Manhattan distance between any two points
m_dist = fn {x1, y1}, {x2, y2} -> abs( x1 - x2 ) + abs( y1 - y2 ) end

init_data = fn lines -> matrix.(lines) |> matrix_map.() end

asteroid_locs = fn grid ->
  Enum.group_by(grid, &elem(&1,1), &elem(&1,0)) |>
  Map.get("#") |> MapSet.new
end

points_to_check = fn {site_x, site_y}, {target_x, target_y} ->
  [x_diff, y_diff] = [abs(site_x - target_x), abs(site_y - target_y)]
  gnum = Integer.gcd(x_diff, y_diff)
  cond do
    site_x == target_x and y_diff > 1 ->
      i = if site_y < target_y, do: 1, else: -1
      Range.new(site_y + i, target_y - i, i) |> Enum.map(&({site_x, &1}))
    site_y == target_y and x_diff > 1 ->
      i = if site_x < target_x, do: 1, else: -1
      Range.new(site_x + i, target_x - i, i) |> Enum.map(&({&1, site_y}))
    gnum > 1 ->
      [x_inc, y_inc] = [div(x_diff, gnum), div(y_diff, gnum)]
      cond do
        site_x < target_x and site_y < target_y ->
          [Range.new(site_x + x_inc, target_x - x_inc, x_inc),
           Range.new(site_y + y_inc, target_y - y_inc, y_inc)] |> Enum.zip
        site_x < target_x and site_y > target_y ->
          [Range.new(target_x - x_inc, site_x + x_inc, -x_inc),
           Range.new(target_y + y_inc, site_y - y_inc, y_inc)] |> Enum.zip
        site_x > target_x and site_y < target_y ->
          [Range.new(site_x - x_inc, target_x + x_inc, -x_inc),
           Range.new(site_y + y_inc, target_y - y_inc, y_inc)] |> Enum.zip
        site_x > target_x and site_y > target_y ->
          [Range.new(target_x + x_inc, site_x - x_inc, x_inc),
           Range.new(target_y + y_inc, site_y - y_inc, y_inc)] |> Enum.zip
        true -> raise ArgumentError
      end
    true -> []
  end
end

visible_from? = fn site, target, data ->
  points_to_check.(site, target) |> MapSet.new |> MapSet.disjoint?(data)
end

visible_counts = fn data ->
  Enum.reduce(data, %{}, fn site, counts ->
    num_visible = Enum.count(MapSet.delete(data, site),
      fn target -> visible_from?.(site, target, data) end)
    Map.put(counts, site, num_visible)
  end) |> Enum.group_by(&elem(&1,1), &elem(&1,0))
end

data = read_input.() |> init_data.() |> asteroid_locs.()
rank = visible_counts.(data)
best = Map.keys(rank) |> Enum.max

IO.puts("Part 1: #{best}")


# For Part 2, we'll have to calculate the slope of
# the line between each asteroid and the laser site.
{site_x, site_y} = rank[best] |> hd

data = MapSet.delete(data, {site_x, site_y})
site_dist = fn pt -> m_dist.({site_x, site_y}, pt) end

sort_quadrant = fn data, fn_x ->
  Enum.filter(data, fn {x,_} -> fn_x.(x) end) |>
  Enum.map(fn {x,y} -> {{x,y}, (y - site_y) / (x - site_x)} end) |>
  Enum.group_by(&elem(&1,1), &elem(&1,0)) |>
  Enum.map(fn {k,v} -> {k, Enum.min_by(v, site_dist)} end) |>
  List.keysort(0) |> Enum.map(&elem(&1,1))
end

sort_axis = fn data, fn_y ->
  Enum.filter(data, fn {x,y} -> x == site_x and fn_y.(y) end) |>
  Enum.min_by(site_dist, fn -> nil end)
end

# first, check the smaller y-axis (can't divide by zero)
z1 = fn data -> sort_axis.(data, fn y -> y < site_y end) end
q1 = fn data -> sort_quadrant.(data, fn x -> x > site_x end) end
z2 = fn data -> sort_axis.(data, fn y -> y > site_y end) end
q2 = fn data -> sort_quadrant.(data, fn x -> x < site_x end) end

to_vaporize = fn data ->
  Enum.concat([z1.(data) | q1.(data)], [z2.(data) | q2.(data)]) |>
  Enum.reject(&is_nil/1) # sort_axis returns nil for empty set
end

do_sweep = fn data ->
  Enum.reduce_while(Stream.cycle([1]), {data, []}, fn _, {data, zapped} ->
    if Enum.empty?(data) do {:halt, zapped}
    else
      pts = to_vaporize.(data)
      data = MapSet.new(pts) |> MapSet.symmetric_difference(data)
      {:cont, {data, zapped ++ pts}}
    end
  end)
end

{x_200, y_200} = do_sweep.(data) |> Enum.at(199)

IO.puts("Part 2: #{100 * x_200 + y_200}")
