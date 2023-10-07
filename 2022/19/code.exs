# Solution to Advent of Code 2022, Day 19
# https://adventofcode.com/2022/day/19

Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

max_t = 3  # there are four types - listed in order of complexity
t_list = ~w[ore clay obsidian geode]s
typeid = fn s -> Enum.find_index(t_list, &(&1 == s)) end

parse_lines = fn lines ->
  Map.new(lines, fn l ->
    [_, idnum] = Regex.run(~r/^Blueprint (\d+):/, l)
    recipes = Regex.scan(~r/Each (\w+) robot costs ([^.]+)\./, l)
    bp = Map.new(recipes, fn [_, type, recipe] ->
      cost = String.split(recipe, " and ")  # max 2 elements per recipe
      bpt = Map.new(cost, fn c ->
        [num, thing] = String.split(c)
        {typeid.(thing), String.to_integer(num)}
      end)
      {typeid.(type), bpt}
    end)
    {String.to_integer(idnum), bp}
  end)
end

blueprints = read_input.() |> parse_lines.()

# Calculate the maximum possible robot cost for each material.
# We never try to make a robot that we have as many of as we need
# to cover any possible cost of that resource in one minute,
# because we can only build one robot per minute.
max_costs = fn bp ->
  t_costs = Map.values(bp) |> Enum.flat_map(&Map.to_list/1)
    |> Util.group_tuples(0, 1)  # type => costs
  max_c = fn t -> {t, Map.get(t_costs, t, [0]) |> Enum.max} end
  Map.new(0..(max_t - 1), max_c) |> Map.put(max_t, 999999999999999)
end                                        # we always need more geodes

bp_costs = Map.new(blueprints, fn {k, bp} -> {k, max_costs.(bp)} end)
      
# Given a set of blueprints and resources, can we make this type of robot?
can_make? = fn idnum, typeid, resources, robots, minutes_left ->
  rs_num = Map.get(resources, typeid, 0)  # available resources of this type
  rt_num = Map.get(robots, typeid, 0)  # number of robots built of this type
  {costs, max_cost} = {blueprints[idnum][typeid], bp_costs[idnum][typeid]}
  cond do
    rt_num >= max_cost -> false
    rt_num > 0 and minutes_left != nil and typeid != max_t
      and rt_num * minutes_left + rs_num >= minutes_left * max_cost -> false
    true ->  # Do we have the resources we need?
      Enum.all?(costs, fn {k, v} -> Map.get(resources, k, 0) >= v end)
  end
end

produce = fn robots, resources ->
  Map.merge(robots, resources, fn _, v1, v2 -> v1 + v2 end)
end

build_robot = fn idnum, typeid, resources, robots ->
  if not can_make?.(idnum, typeid, resources, robots, nil)
  do {resources, robots}
  else 
    resources = blueprints[idnum][typeid] |>
      Map.merge(resources, fn _, v1, v2 -> v2 - v1 end)
    {produce.(robots, resources), Map.update(robots, typeid, 1, &(&1 + 1))}
  end
end

new_paths = fn paths, resources, robots, minutes_left ->
  new_path = {resources, robots, minutes_left - 1}
  paths = if minutes_left > 0, do: [new_path | paths], else: paths
  {paths, Map.get(resources, max_t, 0)}
end

branch_out = fn paths, idnum, resources, robots, minutes_left ->
  types = Enum.filter(0..max_t, fn t ->
          can_make?.(idnum, t, resources, robots, minutes_left) end)
  # if we can make a geode robot, ignore other possibilities
  if max_t in types do
    {resources, robots} = build_robot.(idnum, max_t, resources, robots)
    new_paths.(paths, resources, robots, minutes_left)
  else
    {paths, _} = Enum.reduce(types, {paths, nil}, fn t, {paths, _} ->
      {resources, robots} = build_robot.(idnum, t, resources, robots)
      new_paths.(paths, resources, robots, minutes_left)
    end)
    # production step (the "do nothing" choice)
    new_paths.(paths, produce.(robots, resources), robots, minutes_left)
  end
end

# cache previously visited states to avoid duplicated effort
cache_key = fn idnum, resources, robots, minutes_left ->
  # discard irrelevant resources for caching purposes
  resources = Enum.reduce(0..max_t - 1, resources, fn t, resources ->
    cap = 2 * bp_costs[idnum][t] - 2
    case Map.get(resources, t, 0) do
      rs when rs > cap -> Map.put(resources, t, cap)
      _ -> resources
    end
  end)
  for(t <- 0..max_t, re = Map.get(resources, t, 0),
      rb = Map.get(robots, t, 0), into: [], do:
      Enum.join([t, re, rb], ","))
  |> List.insert_at(0, minutes_left) |> Enum.join("|")
end

calc_path = fn idnum, minutes_left ->
  paths = [{%{}, %{typeid.("ore") => 1}, minutes_left - 1}]  # initial values
  data = Enum.reduce_while(Stream.cycle([1]),
            %{paths: paths, seen: MapSet.new, best: 0}, fn _, data ->
    if Enum.empty?(data.paths) do {:halt, data}
    else
      [{resources, robots, minutes_left} | paths] = data.paths
      skey = cache_key.(idnum, resources, robots, minutes_left)
      new_data = %{data | paths: paths, seen: MapSet.put(data.seen, skey)}
      # what if we could build another geode robot every remaining turn?
      [g_rs, g_rb] = Enum.map([resources, robots], fn r ->
        Map.get(r, max_t, 0) end)
      {g_rs, _} = Enum.reduce(0..minutes_left, {g_rs, g_rb},
        fn _, {g_rs, g_rb} -> {g_rs + g_rb, g_rb + 1} end)
      cond do
        # have we seen this state before?
        MapSet.member?(data.seen, skey) -> {:cont, new_data}
        # if we can't possibly beat our best, abandon this path
        g_rs <= data.best -> {:cont, new_data}
        true ->
          {paths, geodes} = branch_out.(paths, idnum, resources,
                                        robots, minutes_left)
          new_best = Enum.max([data.best, geodes])
          {:cont, %{new_data | paths: paths, best: new_best}}
      end
    end
  end)
  {idnum, data.best}
end

# Serial calculation takes 5.4 sec
# By comparison, Perl version takes 16 sec

#quality_sum = Enum.reduce(Map.keys(blueprints), 0, fn idnum, q ->
#  {_, best} = calc_path.(idnum, 24)
#  IO.puts("Best for #{idnum} is #{best}.")
#  q + idnum * best
#end)

# Parallel calculation takes 2.2 sec

start_task = fn idnum, t -> Task.async(fn -> calc_path.(idnum, t) end) end

await_task_result = fn task -> Task.await(task) |> Tuple.product end

quality_sum = Map.keys(blueprints) |> Enum.map(&start_task.(&1, 24))
  |> Enum.map(await_task_result) |> Enum.sum

IO.puts("Part 1: #{quality_sum}")


# hungry elephant eats all but the first 3 blueprints
blueprints = Map.filter(blueprints, fn {k, _} -> k in 1..3 end)

await_task_result = fn task -> Task.await(task) |> elem(1) end

total32 = Map.keys(blueprints) |> Enum.map(&start_task.(&1, 32))
  |> Enum.map(await_task_result) |> Enum.product

IO.puts("Part 2: #{total32}")

# elapsed time: approx. 3.4 seconds for both parts together
