# Solution to Advent of Code 2017, Day 13
# https://adventofcode.com/2017/day/13

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

all_matches = fn str, pat ->
  Regex.scan(pat, str, capture: :all_but_first) |> Enum.concat
end

read_numbers = fn str ->
  all_matches.(str, ~r/(\d+)/) |> Enum.map(&String.to_integer/1)
end

parse_line = fn line -> read_numbers.(line) |> List.to_tuple end
parse_input = fn input -> Map.new(input, parse_line) end

init_state = fn data ->
  Map.new(data, fn {k, v} -> {k, %{range: v, pos: 1, dir: 1}} end)
end

step = fn %{range: range, pos: pos, dir: dir} = layer ->
  cond do
    pos == 1 -> %{layer | pos: pos + 1, dir: 1}
    pos == range -> %{layer | pos: pos - 1, dir: -1}
    true -> %{layer | pos: pos + dir, dir: dir}
  end
end

step_all = fn state ->
  Enum.reduce(state, state, fn {depth, layer}, state ->
    Map.put(state, depth, step.(layer))
  end)
end

state = read_input.() |> parse_input.() |> init_state.()

severity = fn ->
  limit = Map.keys(state) |> Enum.max
  Enum.reduce(0..limit, {[], state}, fn depth, {caught, state} ->
    layer = Map.get(state, depth)
    if is_nil(layer) or layer.pos != 1, do: {caught, step_all.(state)},
    else: {[depth * layer.range | caught], step_all.(state)}
  end) |> elem(0) |> Enum.sum
end

IO.puts("Part 1: #{severity.()}")


# This is another exercise where the iterative solution took too long,
# so I had to look up the mathematical solution elsewhere. On a hunch,
# I cut the total execution time about another two thirds by stepping
# by two instead of one, since the mod base is always an even number.
# (Might not work for all inputs? I am not a math person.)
find_escape = fn ->
  Enum.reduce_while(Stream.iterate(0, &(&1 + 2)), nil, fn t, _ ->
    caught? =  # Enum.any? would also work here but is noticeably slower
      Enum.reduce_while(state, false, fn {depth, layer}, _ ->
        if Integer.mod(depth + t, 2 * layer.range - 2) == 0,
        do: {:halt, true}, else: {:cont, false}
      end)
    if caught?, do: {:cont, nil}, else: {:halt, t}
  end)
end

IO.puts("Part 2: #{find_escape.()}")
