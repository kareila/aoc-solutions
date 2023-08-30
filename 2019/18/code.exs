# Solution to Advent of Code 2019, Day 18
# https://adventofcode.com/2019/day/18

require Recurse  # for search()

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

data = read_input.() |> matrix.() |> matrix_map.()

# We don't need to explore every location in the maze, just the
# keys and doors - but we need to know the distance between each.
# Treat this as a node graph with weighted edges and use BFS.

get_nodes = fn data ->
  for {{x, y}, v} <- data, v not in [".", "#"], into: %{}, do: {v, {x, y}}
end

check_loc = fn loc, visited, grid ->
  found = Map.get(grid, loc, "#")
  cond do
    MapSet.member?(visited, loc) -> []
    found == "#" -> []
    found == "." -> [loc]
    found == "@" -> [loc]  # not a destination
    found in ~w(1 2 3 4)s -> [loc]  # for Part 2
    true -> [found]
  end
end

explore_loc = fn {px, py}, visited, grid ->
  [{px, py - 1}, {px, py + 1}, {px - 1, py}, {px + 1, py}] |>
  Enum.flat_map(fn loc -> check_loc.(loc, visited, grid) end) |>
  Enum.split_with(&is_tuple/1)
end

find_neighbors = fn loc, grid ->
  init = {[[loc]], MapSet.new([loc]), []}
  Enum.reduce_while(Stream.cycle([1]), init, fn _, {queue, visited, found} ->
    if Enum.empty?(queue) do {:halt, found}
    else
      [path | queue] = queue
      {nxt_locs, nxt_found} = explore_loc.(hd(path), visited, grid)
      nxt_found = Enum.map(nxt_found, fn v -> {v, length(path)} end)
      nxt_queue = Enum.map(nxt_locs, fn loc -> [loc | path] end)
      visited = MapSet.new(nxt_locs) |> MapSet.union(visited)
      {:cont, {queue ++ nxt_queue, visited, found ++ nxt_found}}
    end
  end)
end

# node => [{node, dist}, {node, dist}, ...]
graph_nodes = fn data ->
  Enum.reduce(get_nodes.(data), %{}, fn {val, loc}, neighbors ->
    Map.put(neighbors, val, find_neighbors.(loc, data))
  end)
end

# Now that we've completed our graph of nodes and distances,
# we can begin computing the shortest path to get all the keys.
#
# Start by formulating the calculation that takes a node and a
# list of already held keys and tells us the minimum distance to
# every other node that we can reach using that set of held keys.

check_distance = fn nodes, dist, best_dists ->
  # Only keep the distances that are better than what we already had.
  better = fn {n, d} -> d < Map.get(best_dists, n, 999_999_999) end
  Enum.map(nodes, fn {n, d} -> {n, d + dist} end) |>
  Enum.filter(better) |> Map.new
end

reachable_keys = fn start, held_keys, node_graph ->
  queue = node_graph[start] |> List.keysort(1)  # closer nodes first
  best_dists = Map.new(queue)  # nearest neighbor distances are always best
  Enum.reduce_while(Stream.cycle([1]), {queue, best_dists, %{}},
    fn _, {queue, best_dists, reachable} ->
      if Enum.empty?(queue) do {:halt, Map.to_list(reachable)}
      else
        [{nxt, dist} | queue] = queue
        cond do
          nxt =~ ~r"[a-z]" and nxt not in held_keys ->
            # This is a reachable key we don't already hold. Keep it
            # if we haven't seen it yet (queue is ordered by distance).
            {:cont, {queue, best_dists, Map.put_new(reachable, nxt, dist)}}
          nxt =~ ~r"[A-Z]" and String.downcase(nxt) not in held_keys ->
            # This is a door we can't open, so skip it.
            {:cont, {queue, best_dists, reachable}}
          true ->
            # Check this node's neighbors and insert them in the queue
            # only if the best distance from this point is an improvement.
            new_dist = check_distance.(node_graph[nxt], dist, best_dists)
            best_dists = Map.merge(best_dists, new_dist)
            queue = Map.to_list(new_dist) ++ queue
            {:cont, {List.keysort(queue, 1), best_dists, reachable}}
        end
      end
    end)
end

reachable_fn = fn node_graph ->
  fn start, held -> reachable_keys.(start, held, node_graph) end
end

# Finally, we're ready to do a recursive search for the best path.
# Count how many keys we need to find so that we know when we're done.

nodes_pt1 = graph_nodes.(data)

num_keys = Map.keys(nodes_pt1) |> Enum.count(&(&1 =~ ~r"[a-z]"))

min_steps1 = Recurse.search(["@"], num_keys, reachable_fn.(nodes_pt1))

IO.puts("Part 1: #{min_steps1}")


# Now we need to edit the graph data.

{start_x, start_y} = get_nodes.(data) |> Map.get("@")

new_starts = [{start_x - 1, start_y - 1}, {start_x - 1, start_y + 1},
              {start_x + 1, start_y - 1}, {start_x + 1, start_y + 1}]
  |> Enum.zip(~w(1 2 3 4)s) |> Map.new

erased = [{start_x, start_y}, {start_x - 1, start_y}, {start_x + 1, start_y},
          {start_x, start_y - 1}, {start_x, start_y + 1}]
  |> Map.from_keys("#")

new_data = data |> Map.merge(new_starts) |> Map.merge(erased)

nodes_pt2 = graph_nodes.(new_data)

min_steps2 = Recurse.search(~w(1 2 3 4)s, num_keys, reachable_fn.(nodes_pt2))

IO.puts("Part 2: #{min_steps2}")
