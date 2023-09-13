# Solution to Advent of Code 2018, Day 17
# https://adventofcode.com/2018/day/17

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

matrix_map = fn matrix ->
  for {x, y, v} <- matrix, into: %{}, do: { {x, y}, v }
end

# returns a list of rows
order_points = fn grid ->
  List.keysort(grid, 0) |> Enum.group_by(&elem(&1,1)) |>
  Map.to_list |> List.keysort(0) |> Enum.map(&elem(&1,1))
end

min_max_x = fn matrix -> Enum.map(matrix, &elem(&1,0)) |> Enum.min_max end
min_max_y = fn matrix -> Enum.map(matrix, &elem(&1,1)) |> Enum.min_max end

all_matches = fn str, pat ->
  Regex.scan(pat, str, capture: :all_but_first) |> Enum.concat
end

read_numbers = fn str ->
  all_matches.(str, ~r/(\d+)/) |> Enum.map(&String.to_integer/1)
end

# I found this additional example to be helpful
_fake_input = fn -> """
x=499, y=11..21
y=21, x=500..515
x=516, y=12..21
y=18, x=508..510
x=508, y=9..17
x=510, y=9..17
x=496, y=28..31
y=28, x=497..501
y=31, x=497..501
x=502, y=28..31
x=487, y=23..34
y=34, x=488..507
x=508, y=24..34
""" |> String.split("\n", trim: true)
end

origin = {500, 0}

parse_line = fn line ->
  [n1, n2, n3] = read_numbers.(line)
  case String.first(line) do
    "x" -> Enum.map(n2..n3, fn y -> {n1, y, "#"} end)
    "y" -> Enum.map(n2..n3, fn x -> {x, n1, "#"} end)
  end
end

parse_lines = fn lines ->
  Enum.flat_map(lines, parse_line) |> matrix_map.() |> Map.put(origin, "+")
end

# needed for viewing sparse map when debugging
_normalize_grid = fn grid ->
  {x0, x1} = min_max_x.(grid)
  {y0, y1} = min_max_y.(grid)
  sand = for i <- x0 .. x1, j <- y0 .. y1, do: {i, j, "."}
  Map.merge(matrix_map.(sand), matrix_map.(grid))
end

point_value = fn data, {x, y} -> Map.get(data, {x, y}, ".") end

is_wall? = fn data, {x, y} -> point_value.(data, {x, y}) == "#" end
is_filled? = fn data, {x, y} -> point_value.(data, {x, y}) != "." end

find_edge = fn x, y, limit, fnc, data ->
  Enum.reduce_while(Stream.iterate(x, fnc), nil, fn i, _ ->
    if i == fnc.(limit) or is_wall?.(data, {fnc.(i), y}),
    do: {:halt, i}, else: {:cont, nil} end)
end

fill_rows = fn x, y, data ->
  {x_min, x_max} = Map.keys(data) |> min_max_x.()
  Enum.reduce_while(Stream.cycle([1]), {y, data}, fn _, {y, data} ->
    x1 = find_edge.(x, y, x_min, &(&1 - 1), data)
    x2 = find_edge.(x, y, x_max, &(&1 + 1), data)
    layer = Enum.map(x1..x2, fn i -> {i, y} end)
    floor = Enum.map(x1..x2, fn i -> {i, y + 1} end)
    if Enum.all?(floor, &is_filled?.(data, &1)) do
      {:cont, {y - 1, Map.merge(data, Map.from_keys(layer, "~"))}}
    else
      {:halt, {x, y, Map.put(data, {x, y}, "|")}}
    end
  end)
end

drop_water = fn {x, y}, data ->
  depth = Map.keys(data) |> min_max_y.() |> elem(1)
  Enum.reduce_while(Stream.iterate(y, &(&1 + 1)), data, fn j, flow ->
    nxt = point_value.(data, {x, j + 1})
    cond do
      j == depth -> {:halt, flow}  # out of bounds
      nxt == "|" -> {:halt, flow}  # duplicate path
      nxt == "." -> {:cont, Map.put(flow, {x, j + 1}, "|")}
      true -> {:halt, fill_rows.(x, j, flow)}
    end
  end)
end

mark_flow = fn x, y, minmax, fnc, cmp, data ->
  limit = Map.keys(data) |> min_max_x.() |> elem(minmax)
  Enum.reduce_while(Stream.iterate(x, fnc), data, fn i, flow ->
    nxt = point_value.(data, {fnc.(i), y})
    flr = point_value.(data, {i, y + 1})
    cond do
      cmp.(i, fnc.(limit)) -> {:halt, flow}  # out of bounds
      flr in [".", "|"] -> {:halt, drop_water.({i, y}, flow)}
      nxt in [".", "|"] -> {:cont, Map.put(flow, {fnc.(i), y}, "|")}
      true -> {:halt, flow}  # found a barrier
    end
  end)
end

# these need to be passed as functions to always have recent data
continue_flow = fn {x, y, _} ->
  [fn data -> mark_flow.(x, y, 0, &(&1 - 1), &</2, data) end,  # left
   fn data -> mark_flow.(x, y, 1, &(&1 + 1), &>/2, data) end]  # right
end

fill = fn data ->
  init = fn data -> drop_water.(origin, data) end
  Enum.reduce_while(Stream.cycle([1]), {[init], data}, fn _, {flow, data} ->
    if Enum.empty?(flow) do {:halt, data}
    else
      [exec | flow] = flow
      state = exec.(data)
      nxt = if is_tuple(state), do: elem(state, 2), else: state
      flow = if is_map(state), do: flow, else: flow ++ continue_flow.(state)
      {:cont, {flow, Map.merge(data, nxt)}}
    end
  end)
end

# Once I figured out how to model the flow correctly, I had to remove
# all flow tiles above the highest clay wall to get the correct answer.

remove_top = fn data ->
  Map.keys(data) |> order_points.() |>
  Enum.reduce_while(data, fn row, data ->
    vals = Map.take(data, row) |> Map.values
    if "#" in vals, do: {:halt, data},
    else: {:cont, Map.drop(data, row)}
  end)
end

water_tile_count = fn data ->
  remove_top.(data) |> Map.values |> Enum.count(fn v -> v in ["~", "|"] end)
end

data = read_input.() |> parse_lines.() |> fill.()

IO.puts("Part 1: #{water_tile_count.(data)}")


reservoir_count = fn data ->
  Map.values(data) |> Enum.count(fn v -> v == "~" end)
end

IO.puts("Part 2: #{reservoir_count.(data)}")
