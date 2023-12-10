# Solution to Advent of Code 2023, Day 8
# https://adventofcode.com/2023/day/8

Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_line = fn line ->
  [loc, left, right] = Util.all_matches(line, ~r/(\w+)/)
  {loc, %{"L" => left, "R" => right}}
end

# multiple locs, cycles and periods are used in Part 2
parse_input = fn [dirs | maps] ->
  %{dirs: String.graphemes(dirs), maps: Map.new(maps, parse_line),
    locs: ["AAA"], cycles: 0, periods: []}
end

take_step = fn t, %{dirs: dirs, maps: maps, locs: locs} = data ->
  nxt = Enum.at(dirs, Integer.mod(t - 1, length(dirs)))
  %{data | locs: Enum.map(locs, &(maps[&1][nxt]))}
end

walk_path = fn data ->
  Enum.reduce_while(Stream.iterate(1, &(&1 + 1)), data, fn t, data ->
    data = take_step.(t, data)
    if data.locs == ["ZZZ"], do: {:halt, t}, else: {:cont, data}
  end)
end

data = read_input.() |> parse_input.()

IO.puts("Part 1: #{walk_path.(data)}")


find_starts = fn %{maps: maps} = data ->
  %{data | locs: Map.keys(maps) |> Enum.filter(&String.ends_with?(&1, "A"))}
end

# now the walk_path approach will take too long - time to count cycles
# as multiples of the list of directions (as intuited from the example)
walk_cycle = fn %{dirs: dirs, cycles: c, periods: periods} = data ->
  data = %{Enum.reduce(1..length(dirs), data, take_step) | cycles: c + 1}
  ended = Enum.filter(data.locs, &String.ends_with?(&1, "Z"))
  if Enum.empty?(ended), do: data,
  else: %{data | locs: data.locs -- ended, periods: [data.cycles | periods]}
end

find_periods = fn data ->
  Enum.reduce_while(Stream.cycle([1]), data, fn _, data ->
    data = walk_cycle.(data)
    if Enum.empty?(data.locs), do: {:halt, data}, else: {:cont, data}
  end)
end

# unsurprisingly, the periods are all prime numbers,
# so just multiply them all together to get the LCM
steps_from_cycles = fn data ->
  %{dirs: dirs, periods: periods} = find_periods.(data)
  Enum.product(periods) * length(dirs)
end

IO.puts("Part 2: #{find_starts.(data) |> steps_from_cycles.()}")
