# Solution to Advent of Code 2019, Day 24
# https://adventofcode.com/2019/day/24

split_lines = fn str -> String.split(str, "\n", trim: true) end

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> split_lines.()
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

init_data = read_input.() |> matrix.() |> matrix_map.()

adj_coords = fn {x, y} ->
  [{x - 1, y}, {x + 1, y}, {x, y - 1}, {x, y + 1}]
end

next_val = fn adj, v, data ->
  bugs_adj = Enum.count(adj, fn p -> Map.get(data, p, ".") == "#" end)
  case v do
    "#" -> if bugs_adj == 1, do: "#", else: "."
    "." -> if bugs_adj in [1,2], do: "#", else: "."
    _ -> raise(RuntimeError, "invalid grid value")
  end
end

print_grid = fn data ->
  data = Map.put_new(data, {2,2}, "?")  # for inspecting Part 2
  Map.keys(data) |> Enum.group_by(&elem(&1,1)) |> Map.to_list |>
    List.keysort(0) |> Enum.map_join("\n", fn {_, row} ->
      Enum.map_join(List.keysort(row, 0), &(data[&1])) end)
end

# calculations for Part 1

step = fn data ->
  Map.new(data, fn {pos, v} ->
    {pos, next_val.(adj_coords.(pos), v, data)}
  end)
end

find_repeat = fn data ->
  Enum.reduce_while(Stream.cycle([1]), {data, MapSet.new},
  fn _, {data, prev} ->
    nxt_data = step.(data)
    snapshot = print_grid.(nxt_data)
    if MapSet.member?(prev, snapshot), do: {:halt, snapshot},
    else: {:cont, {nxt_data, MapSet.put(prev, snapshot)}}
  end)
end

grid_vals = fn snapshot ->
   split_lines.(snapshot) |> matrix.() |> Enum.map(&elem(&1,2))
end

bio_rating = fn snapshot ->
  grid_vals.(snapshot) |> Enum.with_index |>
  Enum.reject(fn {v, _} -> v == "." end) |>
  Enum.map(fn {_, i} -> Integer.pow(2, i) end) |> Enum.sum
end

IO.puts("Part 1: #{bio_rating.(find_repeat.(init_data))}")


# Part 2: recursion isn't so bad except for redoing adj_coords

init_3d_data = Map.delete(init_data, {2,2})
            |> Map.new(fn {{x, y}, v} -> {{x, y, 0}, v} end)

init_3d_next = fn z ->
  Map.new(init_3d_data, fn {{x, y, _}, _} -> {{x, y, z}, "."} end)
end

adj_coords_3d = fn pos ->
  # 5x5 grid - need to know exact dimensions now
  case pos do
    # don't use the center
    {2, 2, _} -> raise(RuntimeError, "can't use grid center")
    # top outside edge
    {0, 0, z} -> [{1, 2, z - 1}, {2, 1, z - 1}, {1, 0, z}, {0, 1, z}]
    {4, 0, z} -> [{3, 2, z - 1}, {2, 1, z - 1}, {3, 0, z}, {4, 1, z}]
    {x, 0, z} -> [{2, 1, z - 1}, {x - 1, 0, z}, {x + 1, 0, z}, {x, 1, z}]
    # bottom outside edge
    {0, 4, z} -> [{1, 2, z - 1}, {2, 3, z - 1}, {1, 4, z}, {0, 3, z}]
    {4, 4, z} -> [{3, 2, z - 1}, {2, 3, z - 1}, {3, 4, z}, {4, 3, z}]
    {x, 4, z} -> [{2, 3, z - 1}, {x - 1, 4, z}, {x + 1, 4, z}, {x, 3, z}]
    # other outside edges
    {0, y, z} -> [{1, 2, z - 1}, {1, y, z}, {0, y - 1, z}, {0, y + 1, z}]
    {4, y, z} -> [{3, 2, z - 1}, {3, y, z}, {4, y - 1, z}, {4, y + 1, z}]
    # adjacent to center
    {2, 1, z} -> [{2, 0, z}, {1, 1, z}, {3, 1, z}]
              ++ Enum.map(0..4, fn x -> {x, 0, z + 1} end)
    {2, 3, z} -> [{2, 4, z}, {1, 3, z}, {3, 3, z}]
              ++ Enum.map(0..4, fn x -> {x, 4, z + 1} end)
    {1, 2, z} -> [{1, 1, z}, {1, 3, z}, {0, 2, z}]
              ++ Enum.map(0..4, fn y -> {0, y, z + 1} end)
    {3, 2, z} -> [{3, 1, z}, {3, 3, z}, {4, 2, z}]
              ++ Enum.map(0..4, fn y -> {4, y, z + 1} end)
    # corners of center
    {x, y, z} -> adj_coords.({x,y}) |> Enum.map(&Tuple.append(&1, z))
  end
end

step_3d = fn level, data ->
  data = data |> Map.merge(init_3d_next.(level))
              |> Map.merge(init_3d_next.(abs(level)))
  Map.new(data, fn {pos, v} ->
    {pos, next_val.(adj_coords_3d.(pos), v, data)}
  end)
end

repeat_3d = fn steps ->
  Enum.reduce(1..steps, init_3d_data, fn i, d -> step_3d.(-i, d) end)
  |> Enum.group_by(fn {{_, _, z}, _} -> z end) |> Map.values
# |> Enum.reject(&Enum.all?(&1, fn {_, v} -> v == "." end))
# |> Enum.map_join("\n\n", &print_grid.(Map.new(&1))) |> IO.inspect
  |> List.flatten |> Enum.count(fn {_, v} -> v == "#" end)
end

IO.puts("Part 2: #{repeat_3d.(200)}")

# elapsed time: approx. 0.8 sec for both parts together
