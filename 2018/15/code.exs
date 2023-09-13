# Solution to Advent of Code 2018, Day 15
# https://adventofcode.com/2018/day/15

# This was a beast. Although my initial solving algorithm proved correct,
# I had a subtle edge case bug that was very hard to find. I was skipping
# a combatant if its position key had been removed from the enemies hash
# upon death, but if it was killed by a foe earlier in the reading order,
# and another combatant in between those two moved to the vacated space,
# the one who moved would get two turns! This happened twice in my given
# input. To fix the bug, I had to track the static list and its index
# throughout the round instead of relying on the status of the hash.
#
# Because I spent a lot of time debugging, I didn't plan to put much
# effort into trying to optimize. I knew that find_paths was bogging down,
# and changing `end == stop` to `end in stop` cut the execution time roughly
# in half, to about 2.5 minutes. But then I added the uniq_by filter to omit
# the middle path steps from consideration, and that got it under a second!

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

# returns a list of rows
order_points = fn grid ->
  List.keysort(grid, 0)|> Enum.group_by(&elem(&1,1)) |>
  Map.to_list |> List.keysort(0) |> Enum.map(&elem(&1,1))
end

# needed for debugging
_print_map = fn m_map ->
  Enum.map_join(order_points.(Map.keys(m_map)), "\n", fn row ->
    {s, i} = Enum.map_reduce(List.keysort(row, 0), [], fn k, h ->
      v = Map.fetch!(m_map, k)
      s = if is_tuple(v), do: elem(v, 0), else: v
      i = if is_tuple(v), do: [v], else: []
      {s, [i | h]}
    end)
    i = List.flatten(i) |> Enum.map(fn {v, hp, _} -> "#{v}(#{hp})" end) |>
        Enum.reverse |> Enum.join(", ")
    "#{Enum.join(s)}\t#{i}"
  end) |> IO.puts
end

parse_lines = fn lines ->
  {cavern, enemies} =
    Enum.reduce(matrix.(lines), {%{}, %{}}, fn {x, y, v}, {cv, en} ->
      if v in ["G", "E"] do
        {Map.put(cv, {x, y}, "."), Map.put(en, {x, y}, v)}
      else
        {Map.put(cv, {x, y}, v), en}
      end
    end)
  %{cavern: cavern, enemies: enemies, rounds: 0}
end

current_map = fn data -> Map.merge(data.cavern, data.enemies) end
#read_input.() |> parse_lines.() |> current_map.() |> print_map.()

point_value = fn pos, grid -> Map.get(grid, pos, "#") end
is_open? = fn p, grid -> point_value.(p, grid) == "." end
open_points = fn pts, grid -> Enum.filter(pts, &is_open?.(&1, grid)) end

# these are in "reading order" to avoid using sort_points later
adj_points = fn {x, y}, grid ->
  [{x, y - 1}, {x - 1, y}, {x + 1, y}, {x, y + 1}] |> open_points.(grid)
end

# the cavern is static, so this only needs to run once
map_neighbors = fn data ->
  grid = data.cavern
  start = Map.keys(grid) |> open_points.(grid) |> hd
  Enum.reduce_while(Stream.cycle([1]), {[start], %{}}, fn _, {locs, adj} ->
    if Enum.empty?(locs) do {:halt, adj}
    else
      steps = Enum.reject(locs, &Map.has_key?(adj, &1)) |>
              Map.new(fn p -> {p, adj_points.(p, grid)} end)
      locs = Map.values(steps) |> List.flatten |> Enum.uniq
      {:cont, {locs, Map.merge(adj, steps)}}
    end
  end) |> then(&Map.put(data, :neighbors, &1))
end

# From any given square, we need to know the shortest open path to
# any other given square. But because enemies move around the board,
# any given path can be blocked at any given time. The implication is
# that we need to constantly regenerate ALL possible paths, and then find
# the shortest one that isn't blocked when we need to make our next move.
# However, the only significant parts of each available path are the
# source, destination, and first step, so that collapses the search space.

find_paths = fn stop, loc, data ->
  Enum.reduce_while(Stream.iterate(1, &(&1 + 1)), {[[loc]], MapSet.new},
  fn t, {paths, visited} ->
    paths = Enum.reject(paths, &MapSet.member?(visited, hd(&1)))
    paths = if t < 4, do: paths,
            else: Enum.uniq_by(paths, fn p ->
                  Enum.take(p, 1) ++ Enum.take(p, -2) end)
    found = Enum.filter(paths, &(hd(&1) in stop))
    cond do
      Enum.empty?(paths) -> {:halt, []}
      Enum.empty?(stop) -> {:halt, []}
      length(found) > 0 -> {:halt, found}
      true ->
        visited = MapSet.new(paths, &hd/1) |> MapSet.union(visited)
        paths =
          Enum.flat_map(paths, fn path ->
            Map.fetch!(data.neighbors, hd(path)) |>
            Enum.reject(&Map.has_key?(data.enemies, &1)) |>
            Enum.map(fn nxt -> [nxt | path] end)
          end)
        {:cont, {paths, visited}}
    end
  end)
end

sort_points = fn grid -> order_points.(grid) |> List.flatten end

# it's important to only attack opponents of the opposite type
possible_targets = fn pos, data ->
  type = Map.fetch!(data.enemies, pos) |> elem(0)
  Map.reject(data.enemies, fn {_, {v, _, _}} -> v == type end) |> Map.keys
end

# see if any adjacent squares contain a foe to attack
attackable = fn p, data ->
  targets = possible_targets.(p, data)
  Enum.filter(data.neighbors[p], fn t -> t in targets end)
end

# find the shortest paths to squares next to potential target(s)
find_destinations = fn pos, data ->
  possible_targets.(pos, data) |>
  Enum.flat_map(&Map.fetch!(data.neighbors, &1)) |>
  Enum.uniq |> open_points.(current_map.(data)) |>
  find_paths.(pos, data) |> Enum.group_by(&hd/1)
end

# this is where we decide whether to move or attack
choose_target = fn pos, data ->
  in_range = attackable.(pos, data)
  if length(in_range) > 0 do {:attack, in_range}
  else
    nearest = find_destinations.(pos, data)
    if Enum.empty?(nearest) do {:move, nil}
    else
      choice = Map.keys(nearest) |> sort_points.() |> hd
      step = Map.fetch!(nearest, choice) |>
             Enum.map(&Enum.at(&1, -2)) |> sort_points.() |> hd
      {:move, step}
    end
  end
end

# the elves are allowed to level up in Part 2
init_hp = fn data, pow ->
  e = Map.new(data.enemies, fn {k, v} ->
        if v == "E", do: {k, {v, 200, pow}}, else: {k, {v, 200, 3}}
      end)
  %{data | enemies: e}
end

get_hp = fn p, data -> elem(data.enemies[p], 1) end
get_pow = fn p, data -> elem(data.enemies[p], 2) end

# this handles the results of the actual battles
do_attack = fn pos, targets, %{elist: e, idx: idx, data: data} = state  ->
  foe = Enum.min_by(targets, &get_hp.(&1, data))
  fstat = Map.fetch!(data.enemies, foe)
  hp_new = elem(fstat, 1) - get_pow.(pos, data)
  if hp_new > 0 do
    new_e = Map.replace!(data.enemies, foe, put_elem(fstat, 1, hp_new))
    %{state | data: %{data | enemies: new_e}}
  else  # make sure we skip this position if we haven't reached it yet
    q = Enum.find_index(e, &(&1 == foe))
    idx = if q not in idx, do: idx, else: List.delete(idx, q)
    data = %{data | enemies: Map.delete(data.enemies, foe)}
    %{state | data: data, idx: idx}
  end
end

take_turn = fn %{elist: e, i: i, data: data} = state ->
  pos = Enum.at(e, i)
  if Enum.empty?(possible_targets.(pos, data)) do  # offset partial round count
    {:halt, %{state | data: %{data | rounds: data.rounds - 1}}}
  else
    case choose_target.(pos, data) do
      {:move, nil} -> {:cont, state}
      {:attack, targets} -> {:cont, do_attack.(pos, targets, state)}
      {:move, move} ->
        {v, new} = Map.pop!(data.enemies, pos)
        data = %{data | enemies: Map.put(new, move, v)}
        targets = attackable.(move, data)
        if Enum.empty?(targets), do: {:cont, %{state | data: data}},
        else: {:cont, do_attack.(move, targets, %{state | data: data})}
    end
  end
end

do_round = fn data ->
  {e, idx} = Map.keys(data.enemies) |> sort_points.() |>
             Enum.with_index |> Enum.unzip
  init = %{data: data, elist: e, idx: idx, i: nil}
  data =
    Enum.reduce_while(Stream.cycle([1]), init, fn _, state ->
      if Enum.empty?(state.idx) do {:halt, state}
      else
        [i | idx] = state.idx
        take_turn.(%{state | idx: idx, i: i})
      end
    end) |> Map.fetch!(:data) |> Map.update!(:rounds, &(&1 + 1))
#  IO.puts("AFTER #{data.rounds}")
#  current_map.(data) |> print_map.()
  data
end

still_fighting? = fn data ->
  ct = Enum.frequencies_by(data.enemies, fn {_, {v, _, _}} -> v end)
  map_size(ct) > 1
end

do_combat = fn data ->
  Enum.reduce_while(Stream.cycle([1]), data, fn _, data ->
    data = do_round.(data)
    if still_fighting?.(data), do: {:cont, data}, else: {:halt, data}
  end)
end

sum_hp = fn data ->
  Enum.map(data.enemies, fn {_, v} -> elem(v, 1) end) |> Enum.sum
end

outcome = fn data -> sum_hp.(data) * data.rounds end

data = read_input.() |> parse_lines.() |> map_neighbors.()

result = data |> init_hp.(3) |> do_combat.() |> outcome.()

IO.puts("Part 1: #{result}")


# this needs to work both before and after running init_hp
count_elves = fn data ->
  Enum.count(data.enemies, fn {_, v} ->
    if is_tuple(v), do: elem(v, 0) == "E", else: v == "E"
  end)
end

find_survival = fn ->
  init = count_elves.(data)
  Enum.reduce_while(Stream.iterate(4, &(&1 + 1)), nil, fn pow, _ ->
    d = init_hp.(data, pow) |> do_combat.()
    if count_elves.(d) == init, do: {:halt, outcome.(d)}, else: {:cont, nil}
  end)
end

IO.puts("Part 2: #{find_survival.()}")

# elapsed time: approx. 2 sec for both parts together (!!)
