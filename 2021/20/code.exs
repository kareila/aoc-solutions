# Solution to Advent of Code 2021, Day 20
# https://adventofcode.com/2021/day/20

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

matrix = fn lines ->
  for {line, y} <- Enum.with_index(lines),
      {v, x} <- String.graphemes(line) |> Enum.with_index,
  do: {x, y, v}
end

matrix_map = fn matrix ->
  for {x, y, v} <- matrix, into: %{}, do: { {x, y}, v }
end

parse_input = fn [enhance_vals | lines] ->
  %{enhance_vals: String.graphemes(enhance_vals),
    grid: matrix.(lines) |> matrix_map.(),
    # value of off-grid pixels (can change on enhancement)
    default_val: "."}
end

next_default = fn %{default_val: default, enhance_vals: enhance} = data ->
  nxt = case default do
    "." -> List.first(enhance)
    "#" -> List.last(enhance)
  end
  %{data | default_val: nxt}
end

point_value = fn pos, data -> Map.get(data.grid, pos, data.default_val) end

as_decimal = fn s -> Integer.parse(s, 2) |> elem(0) end

# look at 3x3 grid centered on pixel, return enhanced value
consider = fn {x, y}, data ->
  [{x - 1, y - 1}, {x, y - 1}, {x + 1, y - 1},
   {x - 1, y - 0}, {x, y - 0}, {x + 1, y - 0},
   {x - 1, y + 1}, {x, y + 1}, {x + 1, y + 1}] |>
  Enum.reduce("", fn pos, str -> str <> point_value.(pos, data) end) |>
  String.replace([".", "#"], &Map.fetch!(%{"." => "0", "#" => "1"}, &1)) |>
  as_decimal.() |> then(&Enum.at(data.enhance_vals, &1))
end

min_max_x = fn matrix -> Enum.map(matrix, &elem(&1,0)) |> Enum.min_max end
min_max_y = fn matrix -> Enum.map(matrix, &elem(&1,1)) |> Enum.min_max end

expand_grid = fn data ->
  {x_min, x_max} = min_max_x.(data.grid |> Map.keys)
  {y_min, y_max} = min_max_y.(data.grid |> Map.keys)
  grid =
    for i <- (x_min - 1)..(x_max + 1), j <- [(y_min - 1), (y_max + 1)],
    into: data.grid, do: {{i, j}, data.default_val}
  grid =
    for j <- (y_min - 1)..(y_max + 1), i <- [(x_min - 1), (x_max + 1)],
    into: grid, do: {{i, j}, data.default_val}
  %{data | grid: grid}
end

step = fn data ->
    # Step 1: extend grid one additional pixel in each direction.
    data = expand_grid.(data)
    # Step 2: enhance every pixel in the grid.
    grid = for pos <- Map.keys(data.grid), into: %{},
           do: {pos, consider.(pos, data)}
    # Step 3: update value of unmapped pixels.
    data = next_default.(data)
    # Step 4: copy grid to data.
    %{data | grid: grid}
end

count_pixels = fn data ->
  Enum.count(data.grid, fn {_, v} -> v == "#" end)
end

init_data = read_input.() |> parse_input.()

advance = fn n ->
  Enum.reduce(1..n, init_data, fn _, data -> step.(data) end)
end

IO.puts("Part 1: #{advance.(2) |> count_pixels.()}")
IO.puts("Part 2: #{advance.(50) |> count_pixels.()}")

# elapsed time: approx. 4 sec for both parts together
