# Solution to Advent of Code 2017, Day 25
# https://adventofcode.com/2017/day/25

# returns a list of non-blank BLOCKS from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n\n", trim: true)
end

# Wow, they saved a real parse challenge for the final day...
last_word = fn str -> Regex.run(~r/(\S+)[.:]$/, str) |> Enum.at(1) end

parse_first = fn block ->
  [begin, steps] = String.split(block, "\n")
  b = last_word.(begin)
  s = Regex.run(~r/(\d+)/, steps) |> Enum.at(1) |> String.to_integer
  %{begin: b, steps: s, rules: nil}
end

parse_instructions = fn lines ->
  Enum.reduce(lines, {nil, %{}}, fn line, {if_val, data} ->
    line = String.trim_leading(line)
    word = last_word.(line)
    cond do
      String.starts_with?(line, "If the current value is") ->
        {String.to_integer(word), data}
      is_nil(if_val) -> raise(RuntimeError)
      String.starts_with?(line, "- Write") ->
        {if_val, Map.put(data, :write, String.to_integer(word))}
      String.starts_with?(line, "- Move") ->
        move = Map.fetch!(%{"left" => -1, "right" => 1}, word)
        {if_val, Map.put(data, :move, move)}
      String.starts_with?(line, "- Continue") ->
        {if_val, Map.put(data, :next, word)}
    end
  end)
end

parse_state = fn block ->
  [state | instructions] = String.split(block, "\n", trim: true)
  inst = Enum.chunk_every(instructions, 4) |> Enum.map(parse_instructions)
  %{last_word.(state) => Map.new(inst)}
end

parse_input = fn [first | rest] ->
  rules = Enum.reduce(rest, %{}, &Map.merge(&2, parse_state.(&1)))
  %{parse_first.(first) | rules: rules}
end

data = read_input.() |> parse_input.()

init_state =
  %{tape: MapSet.new, pos: 0, state: data.begin, stop_after: data.steps}

step = fn state ->
  val = if MapSet.member?(state.tape, state.pos), do: 1, else: 0
  rule = Map.fetch!(data.rules, state.state) |> Map.fetch!(val)
  tape_do = if rule.write == 1, do: &MapSet.put/2, else: &MapSet.delete/2
  tape = tape_do.(state.tape, state.pos)
  %{state | tape: tape, pos: state.pos + rule.move, state: rule.next}
end

do_repeat = fn ->
  Enum.reduce_while(Stream.iterate(1, &(&1 + 1)), init_state, fn t, state ->
    if t > state.stop_after, do: {:halt, MapSet.size(state.tape)},
    else: {:cont, step.(state)}
  end)
end

IO.puts("Part 1: #{do_repeat.()}")

# elapsed time: approx. 3 sec

# There is no Part 2!  Merry Christmas!
