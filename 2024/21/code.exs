# Solution to Advent of Code 2024, Day 21
# https://adventofcode.com/2024/day/21

Code.require_file("Util.ex", "..")  # used in Recurse
Code.require_file("Recurse.ex", ".")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

num_keypad =
  %{
    "A" => %{"A" => "A", "<" => "0", "^" => "3"},
    "0" => %{"A" => "0", ">" => "A", "^" => "2"},
    "1" => %{"A" => "1", ">" => "2", "^" => "4"},
    "2" => %{"A" => "2", ">" => "3", "^" => "5", "<" => "1", "v" => "0"},
    "3" => %{"A" => "3", "<" => "2", "^" => "6", "v" => "A"},
    "4" => %{"A" => "4", ">" => "5", "^" => "7", "v" => "1"},
    "5" => %{"A" => "5", ">" => "6", "^" => "8", "<" => "4", "v" => "2"},
    "6" => %{"A" => "6", "<" => "5", "^" => "9", "v" => "3"},
    "7" => %{"A" => "7", ">" => "8", "v" => "4"},
    "8" => %{"A" => "8", "<" => "7", "v" => "5", ">" => "9"},
    "9" => %{"A" => "9", "<" => "8", "v" => "6"}
  }

dir_keypad =
  %{
    "A" => %{"A" => "A", "<" => "^", "v" => ">"},
    "^" => %{"A" => "^", ">" => "A", "v" => "v"},
    ">" => %{"A" => ">", "<" => "v", "^" => "A"},
    "v" => %{"A" => "v", "<" => "<", "^" => "^", ">" => ">"},
    "<" => %{"A" => "<", ">" => "v"}
  }

parse_data = fn lines ->
  form_pairs = fn c -> Enum.zip(["A" | c], c) end
  codes = Enum.map(lines, &form_pairs.(String.graphemes(&1)))
  keypad = fn %{lvl: v} -> if v == 0, do: num_keypad, else: dir_keypad end
  %{codes: codes, vals: Enum.map(lines, &String.trim_trailing(&1, "A")),
    keypad: keypad, form_pairs: form_pairs, cache: %{}, lvl: 0, limit: nil}
end

complexity = fn data, limit ->
  Enum.zip(data.codes, data.vals) |>
  Enum.map_reduce(%{data | limit: limit}, fn {pairs, num}, data ->
    {vals, data} = Enum.map_reduce(pairs, data, &Recurse.pair_value/2)
    {String.to_integer(num) * Enum.sum(vals), data}
  end) |> elem(0) |> Enum.sum
end

data = read_input.() |> parse_data.()

IO.puts("Part 1: #{complexity.(data, 2)}")
IO.puts("Part 2: #{complexity.(data, 25)}")
