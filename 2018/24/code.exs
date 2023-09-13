# Solution to Advent of Code 2018, Day 24
# https://adventofcode.com/2018/day/24

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_line = fn s ->
  [m1, m2, m3] =
    [~r"^(\d+) units each with (\d+) hit points",
     ~r" does (\d+) (\S+) damage at initiative (\d+)",
     ~r"\(([^)]+)"] |> Enum.map(&Regex.run(&1, s, capture: :all_but_first))
  [units, hp] = Enum.map(m1, &String.to_integer/1)
  [d_amt, d_type, init] = Enum.map_every(m2, 2, &String.to_integer/1)
  data = %{units: units, hp: hp, d_amt: d_amt, d_type: d_type,
           initiative: init, mods: %{immune: [], weak: []}}
  if is_nil(m3) do data
  else
    Enum.reduce(String.split(hd(m3), "; "), data, fn attr, data ->
      [mod, type] = String.split(attr, " to ")
      types = String.split(type, ", ")
      %{data | mods: Map.put(data.mods, String.to_atom(mod), types)}
    end)
  end
end

parse_input = fn lines ->
  {lines, immune} =
    Enum.reduce_while(Stream.cycle([1]), {lines, []}, fn _, {lines, army} ->
      [s | lines] = lines
      case s do
        "Infection:" -> {:halt, {lines, army}}
        "Immune System:" -> {:cont, {lines, army}}
        s -> {:cont, {lines, [parse_line.(s) | army]}}
      end
    end)
  %{immune: immune, infection: Enum.map(lines, parse_line)}
end

effective_power = fn group -> group.units * group.d_amt end
power_index = fn g -> {effective_power.(g), g.initiative} end
power_sort = fn army -> Enum.sort_by(army, power_index, :desc) end

select_targets = fn group, enemies ->
  targets = Enum.filter(enemies, fn g -> group.d_type in g.mods.weak end)
  targets = if not Enum.empty?(targets), do: targets,
    else: Enum.reject(enemies, fn g -> group.d_type in g.mods.immune end)
  power_sort.(targets)
end

choose_opponents = fn army1, army2 ->
  Enum.reduce(1..length(army1), {[], power_sort.(army1), army2},
  fn _, {matchups, army1, army2} ->
    [group | army1] = army1
    targets = select_targets.(group, army2)
    if Enum.empty?(targets) do {matchups, army1, army2}
    else
      t = hd(targets)
      {[{group, t} | matchups], army1, List.delete(army2, t)}
    end
  end) |> elem(0)
end

# This builds a queue by reference index, so that we
# know when an attack group has just been eliminated.
all_matchups = fn data ->
  all_groups = data.immune ++ data.infection
  queue =
    choose_opponents.(data.immune, data.infection) ++
    choose_opponents.(data.infection, data.immune) |>
    Enum.sort_by(&elem(&1,0).initiative, :desc) |>
    Enum.flat_map(&Tuple.to_list/1) |>
    Enum.map(fn g -> Enum.find_index(all_groups, &(&1 == g)) end) |>
    Enum.chunk_every(2) |> Enum.map(fn [k, v] -> {k, v} end)
  {queue, all_groups, length(data.immune)}
end

next_attack = fn {k, v}, groups ->
  [g, t] = [Enum.at(groups, k), Enum.at(groups, v)]
  damage =
    cond do
      g.units == 0 -> 0
      g.d_type in t.mods.immune -> 0
      g.d_type in t.mods.weak -> effective_power.(g) * 2
      true -> effective_power.(g)
    end
  if damage == 0 do groups else
    health = Enum.max([t.units * t.hp - damage, 0])
    List.replace_at(groups, v, %{t | units: ceil(health / t.hp)})
  end
end

do_fight = fn data ->
  {queue, all_groups, n} = all_matchups.(data)
  groups = Enum.reduce(queue, all_groups, next_attack)
  [immune, infection] = [Enum.take(groups, n), Enum.drop(groups, n)] |>
    Enum.map(&Enum.reject(&1, fn g -> g.units == 0 end))
  %{immune: immune, infection: infection}
end

total_units = fn army -> Enum.map(army, &(&1.units)) |> Enum.sum end

data = read_input.() |> parse_input.()

do_combat = fn ->
  Enum.reduce_while(Stream.cycle([1]), data, fn _, data ->
    cond do
      length(data.immune) == 0 -> {:halt, total_units.(data.infection)}
      length(data.infection) == 0 -> {:halt, total_units.(data.immune)}
      true -> {:cont, do_fight.(data)}
    end
  end)
end

IO.puts("Part 1: #{do_combat.()}")


boost_immunity = fn data, boost ->
  immune =
    Enum.map(data.immune, fn g -> %{g | d_amt: g.d_amt + boost} end)
  %{data | immune: immune}
end

max_health = fn army -> Enum.map(army, &(&1.units * &1.hp)) |> Enum.max end

# There's a trap in the actual input, where it's possible for
# the two armies to get locked in a stalemate with opposing
# units that are impervious to each other's attacks.
find_victory = fn boost ->
  data = boost_immunity.(data, boost)
  Enum.reduce_while(Stream.cycle([1]), data, fn _, prev_data ->
    data = do_fight.(prev_data)
    cond do
      length(data.immune) == 0 -> {:halt, 0}
      length(data.infection) == 0 -> {:halt, total_units.(data.immune)}
      data == prev_data -> {:halt, 0} # stalemate
      true -> {:cont, data}
    end
  end)
end

# Do a bisection to find the minimum successful boost, with zero as
# one endpoint and the maximum infection group health as the other.
minimum_boost = fn ->
  init_boosts = [{max_health.(data.infection), true}, {0, false}]
  Enum.reduce_while(Stream.cycle([1]), init_boosts, fn _, boosts ->
    prev_pos = List.keyfind!(boosts, true, 1) |> elem(0)
    prev_neg = List.keyfind!(boosts, false, 1) |> elem(0)
    new_boost = div(prev_pos - prev_neg, 2) + prev_neg
    new_boost = new_boost + if new_boost == prev_neg, do: 1, else: 0
    dec_boost = List.keyfind(boosts, new_boost - 1, 0, {nil, true})
    result = find_victory.(new_boost)
    cond do
      result == 0 -> {:cont, [{new_boost, false} | boosts]}
      not elem(dec_boost, 1) -> {:halt, result}
      true -> {:cont, [{new_boost, true} | boosts]}
    end
  end)
end

IO.puts("Part 2: #{minimum_boost.()}")
