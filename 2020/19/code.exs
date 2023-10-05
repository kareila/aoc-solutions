# Solution to Advent of Code 2020, Day 19
# https://adventofcode.com/2020/day/19

Code.require_file("Recurse.ex", ".")

# returns a list of non-blank BLOCKS from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n\n", trim: true)
end

parse_val = fn v ->
  n = Integer.parse(v, 10)
  if n == :error, do: String.trim(v, "\""), else: elem(n, 0)
end

parse_rule = fn line ->
  [k, v] = String.split(line, ": ")
  v = Enum.map(String.split(v, " | "), &String.split/1)
  {String.to_integer(k), Enum.map(v, &Enum.map(&1, parse_val))}
end

parse_rules = fn block ->
  String.split(block, "\n", trim: true) |> Map.new(parse_rule)
end

parse_messages = fn block ->
  String.split(block, "\n", trim: true) |> Enum.map(&String.graphemes/1)
end

parse_input = fn [rules, messages] ->
  %{rules: parse_rules.(rules), messages: parse_messages.(messages)}
end

count_r0_matches = fn data ->
  Enum.count(data.messages, fn msg ->
    len_match = %{rules: data.rules, msg: msg} |> Recurse.match(0)
    length(msg) == Enum.max(len_match, fn -> 0 end)
  end)
end

data = read_input.() |> parse_input.()

IO.puts("Part 1: #{count_r0_matches.(data)}")


new_rules = ["8: 42 | 42 8", "11: 42 31 | 42 11 31"] |> Map.new(parse_rule)

data = %{data | rules: Map.merge(data.rules, new_rules)}

IO.puts("Part 2: #{count_r0_matches.(data)}")
