# Solution to Advent of Code 2022, Day 16
# https://adventofcode.com/2022/day/16

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_lines = fn lines ->
  Enum.reduce(lines, %{links: %{}, rates: %{}}, fn l, data ->
    pat = ~r/^Valve (\w{2}) has flow rate=(\d+); [a-z ]+([A-Z, ]+)$/
    [_, name, r, k] = Regex.run(pat, l)
    links = Map.put(data.links, name, String.split(k, ", "))
    rates = Map.put(data.rates, name, String.to_integer(r))
    %{data | links: links, rates: rates}
  end)
end

init_data = fn paths -> %{ paths: paths, visited: MapSet.new } end

next_steps = fn valves, visited ->
  Enum.reject(valves, &MapSet.member?(visited, &1))
end

eval_pos = fn {stop, links}, data ->
  [cur_path | paths] = data.paths
  pos = hd(cur_path)
  visited = MapSet.put(data.visited, pos)  # not stored yet
  possible = next_steps.(links[pos], data.visited)
  cond do
    pos == stop -> {:halt, length(cur_path)}
    MapSet.member?(data.visited, pos) -> {:cont, %{data | paths: paths}}
    Enum.empty?(possible) -> {:cont, %{data | visited: visited, paths: paths}}
    true -> new_paths = Enum.map(possible, fn p -> [p | cur_path] end)
    paths = new_paths ++ paths |> Enum.sort_by(&length/1)  # slightly faster
    {:cont, %{data | visited: visited, paths: paths}}      #  than appending
  end
end

path_vals = fn links ->
  for i <- Map.keys(links), j <- Map.keys(links), do: {i, j}
end

shortest_paths = fn links ->
  Enum.reduce(path_vals.(links), %{}, fn {start, stop}, paths ->
    data = init_data.([[start]])
    dist = Enum.reduce_while(Stream.cycle([{stop, links}]), data, eval_pos)
    Map.put(paths, {start, stop}, dist)
  end)
end

openable = fn rates ->
  Map.reject(rates, fn {_, v} -> v == 0 end) |> Map.keys
end

# minimum time to open valve at e if currently standing in s
distance = fn s, e, paths -> Map.get(paths, {s,e}) end

# From our current location, walk each possible path between valves and see
# which ordering maximizes the total pressure released in the available time.

path_value = fn [v | prior_path], valves, routes ->
  {tot_d, tot_prod} = Map.get(routes, prior_path, {0,0})
  tot_d = tot_d + distance.(hd(prior_path), v, valves.paths)
  tot_prod = if(tot_d > valves.minutes, do: 0, else:
             tot_prod + ( valves.minutes - tot_d ) * valves.rates[v])
  {tot_d, tot_prod}
end

walk_path = fn path, valves, routes ->
  remaining = valves.closed -- path
  Enum.reduce(remaining, routes, fn v, routes ->
    new_path = [v | path]
    if Map.has_key?(routes, new_path), do: routes,  # already tried it
    else: Map.put(routes, new_path, path_value.(new_path, valves, routes))
  end)
end

prod_val = fn {_, {_, v}} -> v end

# Without parallelization, this takes about 11.7 seconds to run, compared
# to ~9 seconds for the Perl version. Using async reduces it to 3.2 sec!

start_task = fn routes, valves -> Task.async(fn ->
  # keep visiting more valves until routes is no longer changing
  Enum.reduce_while(1..length(valves.closed), routes, fn _, routes ->
    t = map_size(routes)
    routes = Enum.reject(routes, fn r -> prod_val.(r) == 0 end)
          |> Enum.map(&elem(&1,0)) |> Enum.reduce(routes, fn path, routes ->
              walk_path.(path, valves, routes) end)
    if t == map_size(routes), do: {:halt, routes}, else: {:cont, routes}
    end)
  end)
end

await_task_result = fn task -> Task.await(task) |> Enum.max_by(prod_val) end

# start with the shortest path from AA to any closed valve
best_path = fn valves ->
  walk_path.(["AA"], valves, %{})
  |> Enum.map(fn path -> Map.new([path]) |> start_task.(valves) end)
  |> Enum.map(await_task_result) |> Enum.max_by(prod_val)
end

valves = read_input.() |> parse_lines.()
valves = Map.merge(valves, %{paths: shortest_paths.(valves.links),
                   closed: openable.(valves.rates), minutes: 30})

IO.puts("Part 1: #{prod_val.(best_path.(valves))}")


# Still using the not-strictly-correct solution of the above calculation
# with less time on the clock for the human, and then finding the best
# solution for the elephant opening the valves that the human didn't open.
# Supposedly the "right" way to do this is to rerun the algorithm on
# permutations of different valves assigned to one or the other.

valves = Map.put(valves, :minutes, 26)

best_p = best_path.(valves)
best_e = best_path.(%{valves | closed: valves.closed -- elem(best_p, 0)})

IO.puts("Part 2: #{prod_val.(best_p) + prod_val.(best_e)}")

# elapsed time: approx. 3.6 seconds for both parts together
