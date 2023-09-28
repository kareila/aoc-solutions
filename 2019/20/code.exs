# Solution to Advent of Code 2019, Day 20
# https://adventofcode.com/2019/day/20

Code.require_file("Matrix.ex", "..")
Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

data = read_input.() |> Matrix.map |> Map.filter(fn {_, v} -> v != " " end)

# this is needed for Part 2
{_, x_max, _, y_max} = Matrix.limits(data)
{outside_x, outside_y} = {[x_max - 2, 2], [y_max - 2, 2]}

keymatch = fn ks, kmap -> Map.take(kmap, ks) |> Map.keys |> hd end

map_locations = fn ->
  letters = Map.filter(data, fn {_, v} -> v not in [".", "#"] end)
  Enum.reduce(1..div(map_size(letters), 2), {letters, %{}},
  fn _, {letters, portals} ->
    {x1, y1} = List.first(Map.keys(letters))
    {x2, y2} = Util.adj_pos({x1, y1}) |> keymatch.(letters)
    [x1, x2] = if x1 < x2, do: [x1, x2], else: [x2, x1]
    [y1, y2] = if y1 < y2, do: [y1, y2], else: [y2, y1]
    pos =
      cond do
        x1 == x2 -> [{x1, y1 - 1}, {x2, y2 + 1}] |> keymatch.(data)
        y1 == y2 -> [{x1 - 1, y1}, {x2 + 1, y2}] |> keymatch.(data)
      end
    name = Map.fetch!(data, {x1, y1}) <> Map.fetch!(data, {x2, y2})
    letters = letters |> Map.delete({x1, y1}) |> Map.delete({x2, y2})
    {letters, Map.update(portals, name, [pos], fn v -> v ++ [pos] end)}
  end) |> elem(1)
end

map_portals = fn ->
  Enum.reduce(map_locations.(), %{}, fn {k, v}, portals ->
    outside = for {x, y} <- v, x in outside_x or y in outside_y, do: {x, y}
    case k do
      "AA" -> Map.put(portals, :start, hd(v))
      "ZZ" -> Map.put(portals, :stop, hd(v))
      _ ->
        [a, b] = v
        portals |> Map.put(a, b) |> Map.put(b, a) |>
        Map.update(:outside, outside, fn v -> v ++ outside end)
    end
  end)
end

portals = map_portals.()

# basic maze traversal - simplified from Day 18

check_loc = fn loc, visited ->
  found = Map.get(data, loc, "#")
  cond do
    MapSet.member?(visited, loc) -> []
    found == "." -> [loc]
    true -> []
  end
end

explore_loc = fn {px, py}, visited ->
  coords = Util.adj_pos({px, py})
  if not Map.has_key?(portals, {px, py}) do coords
  else [Map.fetch!(portals, {px, py}) | coords] end |>
  Enum.flat_map(fn loc -> check_loc.(loc, visited) end)
end

travel_maze = fn %{start: start, stop: stop, search: search} ->
  Enum.reduce_while(Stream.cycle([1]), {[[start]], MapSet.new([start])},
  fn _, {[path | queue], visited} ->
    [posn | trail] = path
    if posn == stop do {:halt, length(trail)}
    else
      nxt_locs = search.(posn, visited)
      nxt_queue = Enum.map(nxt_locs, fn loc -> [loc | path] end)
      visited = MapSet.new(nxt_locs) |> MapSet.union(visited)
      {:cont, {queue ++ nxt_queue, visited}}
    end
  end)
end

maze1 = %{start: portals.start, stop: portals.stop, search: explore_loc}

IO.puts("Part 1: #{travel_maze.(maze1)}")


# next, modify our traversal code to handle recursion levels

check_loc2 = fn {px, py, level} = loc, visited ->
  found = Map.get(data, {px, py}, "#")
  cond do
    MapSet.member?(visited, loc) -> []
    level < 0 -> []
    found == "." -> [loc]
    true -> []
  end
end

explore_loc2 = fn {px, py, level}, visited ->
  coords = Util.adj_pos({px, py}) |> Enum.map(&Tuple.append(&1, level))
  cond do
    {px, py} in portals.outside ->
      [Tuple.append(portals[{px, py}], level - 1) | coords]
    Map.has_key?(portals, {px, py}) ->
      [Tuple.append(portals[{px, py}], level + 1) | coords]
    true -> coords
  end |> Enum.flat_map(fn loc -> check_loc2.(loc, visited) end)
end

maze2 = %{start: Tuple.append(portals.start, 0),
          stop: Tuple.append(portals.stop, 0),
          search: explore_loc2}

IO.puts("Part 2: #{travel_maze.(maze2)}")
