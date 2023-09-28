# Solution to Advent of Code 2019, Day 10
# https://adventofcode.com/2019/day/10

Code.require_file("Matrix.ex", "..")
Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

asteroid_locs = fn grid ->
  Util.group_tuples(grid, 1, 0) |> Map.get("#") |> MapSet.new
end

points_to_check = fn {site_x, site_y}, {target_x, target_y} ->
  [x_diff, y_diff] = [(site_x - target_x), abs(site_y - target_y)]
  gnum = Integer.gcd(abs(x_diff), y_diff)
  r_fn = fn [s, t, i] -> Range.new(s + i, t - i, i) end
  s_fn = fn [s, t, i] -> Enum.sort([s, t]) ++ [i] |> r_fn.() end
  cond do
    x_diff == 0 and y_diff > 1 ->
      s_fn.([site_y, target_y, 1]) |> Enum.map(&{site_x, &1})
    y_diff == 0 and abs(x_diff) > 1 ->
      s_fn.([site_x, target_x, 1]) |> Enum.map(&{&1, site_y})
    gnum > 1 ->
      [x_inc, y_inc] = [div(x_diff, gnum), div(y_diff, gnum)]
      cond do
        site_y < target_y -> [site_x, target_x, -x_inc]
        target_y < site_y -> [target_x, site_x, x_inc]
        true -> raise ArgumentError
      end |> r_fn.() |> Enum.zip(s_fn.([site_y, target_y, y_inc]))
    true -> []
  end
end

visible_from? = fn site, target, data ->
  points_to_check.(site, target) |> MapSet.new |> MapSet.disjoint?(data)
end

visible_counts = fn data ->
  Enum.map(data, fn site ->
    Enum.count(MapSet.delete(data, site), fn target ->
      visible_from?.(site, target, data)
    end)
  end) |> Enum.zip(data) |> Util.group_tuples(0, 1)
end

data = read_input.() |> Matrix.map |> asteroid_locs.()
rank = visible_counts.(data)
best = Map.keys(rank) |> Enum.max

IO.puts("Part 1: #{best}")


# For Part 2, we'll have to calculate the slope of
# the line between each asteroid and the laser site.
{site_x, site_y} = rank[best] |> hd

data = MapSet.delete(data, {site_x, site_y})
site_dist = fn pt -> Util.m_dist({site_x, site_y}, pt) end
sweep_sort = fn {x, y} -> {{x, y}, (y - site_y) / (x - site_x)} end

sort_quadrant = fn data, fn_x ->
  Enum.filter(data, fn {x,_} -> fn_x.(x) end) |>
  Enum.map(sweep_sort) |> Util.group_tuples(1, 0) |>
  Enum.map(fn {k, v} -> {k, Enum.min_by(v, site_dist)} end) |>
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
