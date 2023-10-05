# Solution to Advent of Code 2020, Day 24
# https://adventofcode.com/2020/day/24

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# north and south are always followed by east or west
parse_line = fn line ->
  Enum.reduce(String.graphemes(line), {[], nil}, fn c, {dirs, stack} ->
    append? = c in ["n", "s"]
    cond do
      not is_nil(stack) and append? -> raise(RuntimeError)
      not is_nil(stack) -> {[stack <> c | dirs], nil}
      append? -> {dirs, c}
      true -> {[c | dirs], nil}
    end
  end) |> elem(0) |> Enum.reverse
end

# https://www.redblobgames.com/grids/hexagons/#coordinates-offset
get_adjacent_map = fn {x, y} ->
  c = [{x - 1, y}, {x + 1, y}]
  if Integer.mod(y, 2) > 0 do
    [{x, y + 1}, {x + 1, y + 1}, {x, y - 1}, {x + 1, y - 1}] ++ c
  else
    [{x - 1, y + 1}, {x, y + 1}, {x - 1, y - 1}, {x, y - 1}] ++ c
  end |> Enum.zip(~w(sw se nw ne w e)s) |> Map.new(fn {v, k} -> {k, v} end)
end

next_coord = fn dir, pos -> get_adjacent_map.(pos) |> Map.fetch!(dir) end
walk_path = fn dirs -> Enum.reduce(dirs, {0,0}, next_coord) end

flip_tile = fn pos, set ->
  if MapSet.member?(set, pos), do: MapSet.delete(set, pos),
  else: MapSet.put(set, pos)
end

do_path = fn path, tiles -> walk_path.(path) |> flip_tile.(tiles) end
init_tiles = fn lines -> Enum.reduce(lines, MapSet.new, do_path) end

tiles = read_input.() |> Enum.map(parse_line) |> init_tiles.()

IO.puts("Part 1: #{MapSet.size(tiles)}")


get_adjacent_coords = fn pos ->
  get_adjacent_map.(pos) |> Map.values |> MapSet.new
end

check_pos = fn pos, tiles ->
  adj = get_adjacent_coords.(pos) |> MapSet.intersection(tiles)
  if MapSet.member?(tiles, pos) do  # this is a black tile
    if MapSet.size(adj) not in [1, 2], do: [pos], else: []
  else  # this is a white tile
    if MapSet.size(adj) == 2, do: [pos], else: []
  end
end

add_to_check = fn p, set -> MapSet.union(set, get_adjacent_coords.(p)) end

apply_rules = fn _, tiles ->
  Enum.reduce(tiles, tiles, add_to_check) |>
  Enum.flat_map(&check_pos.(&1, tiles)) |> Enum.reduce(tiles, flip_tile)
end

tiles = Enum.reduce(1..100, tiles, apply_rules)

IO.puts("Part 2: #{MapSet.size(tiles)}")
