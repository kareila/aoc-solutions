# Solution to Advent of Code 2020, Day 17
# https://adventofcode.com/2020/day/17

Code.require_file("Matrix.ex", "..")
Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

init_cube = for {x, y, v} <- read_input.() |> Matrix.grid,
            into: %{}, do: { {x, y, 0}, v }

sur_pos_z = fn x, y, z ->
  [{x, y} | Util.sur_pos({x, y})] |> Enum.map(&Tuple.append(&1, z))
end

all_pos_3d = fn {x, y, z} ->
  Enum.flat_map((z - 1)..(z + 1), &sur_pos_z.(x, y, &1))
end

list_active = fn grid -> Util.group_tuples(grid, 1, 0) |> Map.fetch!("#") end

split_vals = fn points, grid ->
  Enum.map(points, &{&1, Map.get(grid, &1, ".")}) |> Util.group_tuples(1, 0)
end

get_adj_data = fn p, g, all_fn -> all_fn.(p) -- [p] |> split_vals.(g) end

count_active = fn adj -> elem(adj, 1) |> Map.get("#", []) |> length end

tick = fn data, all_fn ->
  adj_data = list_active.(data) |>
    Map.new(fn p -> {p, get_adj_data.(p, data, all_fn)} end)
  deactivate = Enum.group_by(adj_data, count_active, &elem(&1,0)) |>
    Map.drop([2, 3]) |> Map.values |> List.flatten
  activate = Map.values(adj_data) |> Enum.flat_map(&Map.get(&1, ".", [])) |>
    Enum.frequencies |> Map.filter(&(elem(&1,1) == 3)) |> Map.keys
  data |> Map.merge(Map.from_keys(activate, "#")) |>
    Map.merge(Map.from_keys(deactivate, "."))
end

tick_3d = fn data -> tick.(data, all_pos_3d) end

do_6 = fn tick, init ->
  Enum.reduce(1..6, init, fn _, data -> tick.(data) end) |>
  list_active.() |> length
end

IO.puts("Part 1: #{do_6.(tick_3d, init_cube)}")


init_4d = for {x, y, v} <- read_input.() |> Matrix.grid,
          into: %{}, do: { {x, y, 0, 0}, v }

sur_pos_w = fn x, y, z, w ->
  all_pos_3d.({x, y, z}) |> Enum.map(&Tuple.append(&1, w))
end

all_pos_4d = fn {x, y, z, w} ->
  Enum.flat_map((w - 1)..(w + 1), &sur_pos_w.(x, y, z, &1))
end

tick_4d = fn data -> tick.(data, all_pos_4d) end

IO.puts("Part 2: #{do_6.(tick_4d, init_4d)}")
