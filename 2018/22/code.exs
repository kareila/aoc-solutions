# Solution to Advent of Code 2018, Day 22
# https://adventofcode.com/2018/day/22

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_input = fn lines ->
  [depth, target] = Enum.map(lines, fn line ->
    String.split(line, ": ") |> Enum.at(1)
  end)
  [tx, ty] = String.split(target, ",") |> Enum.map(&String.to_integer/1)
  %{depth: String.to_integer(depth), target: {tx, ty}, origin: {0, 0}}
end

erosion_level = fn geo, input -> Integer.mod(geo + input.depth, 20183) end
region_type = fn g, input -> erosion_level.(g, input) |> Integer.mod(3) end

geo_index! = fn {i, j}, input, data ->
  [{sx, sy}, {tx, ty}] = [input.origin, input.target]
  case {i, j} do
    {^sx, ^sy} -> 0
    {^tx, ^ty} -> 0
    {i, 0} -> i * 16807
    {0, j} -> j * 48271
    {i, j} -> erosion_level.(Map.fetch!(data, {i - 1, j}), input)
            * erosion_level.(Map.fetch!(data, {i, j - 1}), input)
  end
end

geo_vals = fn input ->
  [{sx, sy}, {tx, ty}] = [input.origin, input.target]
  Enum.reduce(sy..ty, %{}, fn j, data ->
    Enum.reduce(sx..tx, data, fn i, data ->
      geo_index!.({i, j}, input, data) |> then(&Map.put(data, {i, j}, &1))
    end)
  end)
end

type_vals = fn input ->
  Map.new(geo_vals.(input), fn {k, g} -> {k, region_type.(g, input)} end)
end

# for use with inspecting the map
_map_index = fn tvals, input ->
  c = %{0 => ".", 1 => "=", 2 => "|"}
  Map.new(tvals, fn {k, v} ->
    cond do
      k == input.origin -> {k, "M"}
      k == input.target -> {k, "T"}
      true -> {k, Map.fetch!(c, v)}
    end
  end)
end

risk_level = fn tvals -> Map.values(tvals) |> Enum.sum end

input = read_input.() |> parse_input.()

IO.puts("Part 1: #{type_vals.(input) |> risk_level.()}")


# Now the real fun begins. We are going to have a lot more
# variables to track: current position, elapsed time, etc.

init_state = Map.merge(input, %{pos: input.origin, tool: :torch, elapsed: 0})

region_desc = fn t ->
  %{0 => :rocky, 1 => :wet, 2 => :narrow} |> Map.fetch!(t)
end

# We will always have the geocache up to our current point,
# but if we step south, we need to map the rest of the row,
# and if we step east, we need to map the rest of the column.
edge_points = fn {x, y} ->
  Enum.map(0..(y - 1)//1, &({x,&1})) ++ Enum.map(0..x, &({&1,y}))
end

# Note: this returns the descriptive type from region_desc,
# not the numeric type needed to calculate Part 1.
type_cache = fn pos, %{data: data, geocache: cache} = state ->
  update_cache = fn pos, cache -> Map.put_new_lazy(cache, pos,
                 fn -> geo_index!.(pos, state, cache) end) end
  if Map.has_key?(data, pos) do {data[pos], state}
  else
    cache = edge_points.(pos) |> Enum.reduce(cache, update_cache)
    type = Map.fetch!(cache, pos) |> region_type.(state) |> region_desc.()
    {type, %{state | data: Map.put(data, pos, type), geocache: cache}}
  end
end

possible_tools = fn t ->
  %{rocky: [:gear, :torch], wet: [:gear, :nil], narrow: [:torch, :nil]}
  |> Map.fetch!(t)
end

# visited timestamps key on both position and tool - only revisit
# a position if we improved our time while holding the same tool
worse? = fn %{elapsed: time} = state, %{visited: visited} ->
  cond do
    visited[state.pos][state.tool] == nil -> false
    visited[state.pos][state.tool] > time -> false
    true -> true
  end
end

tool_choices = fn region, %{elapsed: time} = state, cache ->
  if state.pos == state.target do [:torch]
  else possible_tools.(region) end |>
  Map.from_keys(7) |> Map.replace(state.tool, 0) |>
  Enum.flat_map_reduce(cache, fn {tool, t}, cache ->
    state = %{state | tool: tool, elapsed: time + t}
    if worse?.(state, cache) do {[], cache}
    else
      visited = Map.put_new(cache.visited, state.pos, %{}) |>
                put_in([state.pos, state.tool], time + t)
      {[state], %{cache | visited: visited}}
    end
  end)
end

do_move = fn pos, cache, %{elapsed: t} = state ->
  {type, cache} = type_cache.(pos, cache)
  tool_choices.(type, %{state | pos: pos, elapsed: t + 1}, cache)
end

adj_pos = fn %{pos: {x, y}, target: {tx, ty}}, bound ->
  [{x - 1, y}, {x + 1, y}, {x, y - 1}, {x, y + 1}] |>
  Enum.reject(fn {i, j} -> i < 0 or j < 0 end) |>
  # we have to place some upper bounds to prevent
  # the search from wandering aimlessly forever
  Enum.reject(fn {i, j} -> i > tx + bound or j > ty + bound end)
end

# visited map and data caches should be global across all states
init_cache = fn state, bound ->
  %{data: %{}, geocache: geo_vals.(state), bound: bound, best: nil}
  |> Map.put(:visited, %{state.pos => %{state.tool => state.elapsed}})
  |> Map.merge(input)
end

next_moves = fn state, cache ->
  {_next_states, _cache} = adj_pos.(state, cache.bound) |>
    Enum.flat_map_reduce(cache, fn p, c -> do_move.(p, c, state) end)
end

advance_queue = fn queue, %{best: best} = cache ->
  [state | queue] = queue
  if state.pos == state.target do
    new_best = if best == nil or best > state.elapsed,
               do: state.elapsed, else: best
    {queue, %{cache | best: new_best}}
  else
    {next_states, cache} = next_moves.(state, cache)
    {queue ++ next_states, cache}
  end
end

# find_target = fn bound ->
#   cache = init_cache.(init_state, bound)
#   Enum.reduce_while(Stream.cycle([1]), {[init_state], cache},
#   fn _, {queue, cache} ->
#     if Enum.empty?(queue), do: {:halt, cache.best},
#     else: {:cont, advance_queue.(queue, cache)}
#   end)
# end
#
# With my input, passing a bound parameter of 10 to this function
# produces the right answer in about 78 seconds, but I prefer
# to iteratively discover the smallest area that yields the
# correct solution instead of making semi-informed guesses.
#
# I was excited to realize that my timestamp data included
# all of the information needed to restore a given state!

revive_state = fn pos, %{visited: visited} ->
  Enum.map(Map.fetch!(visited, pos), fn {tool, time} ->
    Map.merge(input, %{pos: pos, tool: tool, elapsed: time})
  end)
end

revive_edges = fn %{target: {tx, ty}} = cache ->
  edge_points.({tx + cache.bound, ty + cache.bound}) |>
  Enum.flat_map(&revive_state.(&1, cache))
end

find_target = fn ->
  bi = input.target |> Tuple.to_list |> Enum.min
  cache = init_cache.(init_state, -bi) |> Map.put(:history, [])
  Enum.reduce_while(Stream.cycle([1]), {[init_state], cache},
  fn _, {queue, cache} ->
    cond do
      not Enum.empty?(queue) -> {:cont, advance_queue.(queue, cache)}
      # stopping after one repeat yields the wrong
      # answer, so this checks for multiple repeats
      Enum.count(cache.history, &(&1 == cache.best)) > 1 ->
        {:halt, cache.best}
      true ->
        # IO.puts("Best for #{cache.bound}: #{cache.best}")
        history = [cache.best | cache.history] |> Enum.reject(&is_nil/1)
        queue = revive_edges.(cache)
        cache = %{cache | history: history, bound: cache.bound + 1}
        {:cont, {queue, cache}}
    end
  end)
end

IO.puts("Part 2: #{find_target.()}")

# elapsed time: approx. 3.1 sec for both parts together

# I'm surprised by how much faster this is - must be because
# the revived edges already start out minimized and only have
# a limited amount of new territory to explore in a given round.
