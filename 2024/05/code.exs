# Solution to Advent of Code 2024, Day 5
# https://adventofcode.com/2024/day/5

Code.require_file("Util.ex", "..")

# returns TWO lists of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n\n") |>
  Enum.map(&String.split(&1, "\n", trim: true))
end

# parse a character-separated list of integers
split_numbers = fn str, c ->
  String.split(str, c) |> Enum.map(&String.to_integer/1)
end

parse_input = fn [rules, updates] ->
  rules =
    Enum.map(rules, &List.to_tuple(split_numbers.(&1, "|"))) |>
    Util.group_tuples(1, 0)
  %{rules: rules, updates: Enum.map(updates, &split_numbers.(&1, ","))}
end

data = read_input.() |> parse_input.()


# if the first page shouldn't be first, move it to the end and try again
check_first = fn _, {[n | rest], sorted} ->
  before = Map.get(data.rules, n, []) |> MapSet.new
  cond do
    Enum.empty?(rest) -> {:halt, Enum.reverse([n | sorted])}
    MapSet.new(rest) |> MapSet.disjoint?(before) ->
      {:cont, {rest, [n | sorted]}}
    true -> {:cont, {List.insert_at(rest, -1, n), sorted}}
  end
end

# reorder an update to obey the given ordering rules
fix_order = &Enum.reduce_while(Stream.cycle([1]), {&1, []}, check_first)

# split up the requests according to whether the given order was already ok
[nofix, fixed] =
  Enum.map(data.updates, fix_order) |> Enum.zip(data.updates) |>
  Enum.split_with(fn {a, b} -> a == b end) |> Tuple.to_list |>
  Enum.map(&Enum.map(&1, fn {v, _} -> v end))

# find the middle of a list with an odd number of elements
middle_elem = &Enum.at(&1, length(&1) |> div(2))

IO.puts("Part 1: #{Enum.map(nofix, middle_elem) |> Enum.sum}")
IO.puts("Part 2: #{Enum.map(fixed, middle_elem) |> Enum.sum}")
