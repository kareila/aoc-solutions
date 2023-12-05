# Solution to Advent of Code 2023, Day 2
# https://adventofcode.com/2023/day/2

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# transform a list of the form ["1 red", "2 green", "6 blue"]
# into a list of the form [{"red", 1}, {"green", 2}, {"blue", 6}]
parse_set = fn set ->
  Enum.map(set, fn pair ->
    [num, color] = String.split(pair)
    {color, String.to_integer(num)}
  end)
end

# calculate the highest number of each color shown in a given game
find_most = fn sets ->
  Enum.group_by(sets, &elem(&1,0), &elem(&1,1)) |>
  Map.new(fn {k, v} -> {k, Enum.max(v)} end)
end

parse_line = fn line ->
  [game, sets] = String.split(line, ": ")
  id = String.split(game) |> List.last |> String.to_integer
  sets = String.split(sets, "; ") |> Enum.map(&String.split(&1, ", "))
  %{sets: Enum.flat_map(sets, parse_set) |> find_most.(), id: id}
end

data = read_input.() |> Enum.map(parse_line)

is_possible? = fn %{sets: sets} ->
  max_cubes = %{"red" => 12, "green" => 13, "blue" => 14}
  within_limit? = fn color -> sets[color] <= max_cubes[color] end
  Map.keys(max_cubes) |> Enum.all?(within_limit?)
end

sum_possible_ids = fn games ->
  Enum.filter(games, is_possible?) |> Enum.map(&(&1.id)) |> Enum.sum
end

IO.puts("Part 1: #{sum_possible_ids.(data)}")


find_power = fn %{sets: sets} -> Map.values(sets) |> Enum.product end
sum_powers = fn games -> Enum.map(games, find_power) |> Enum.sum end

IO.puts("Part 2: #{sum_powers.(data)}")
