# Solution to Advent of Code 2020, Day 8
# https://adventofcode.com/2020/day/8

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_line = fn line ->
  [op, arg] = String.split(line)
  {op, String.to_integer(arg)}
end

init_lines = read_input.() |> Enum.map(parse_line)

init_state = %{acc: 0, idx: 0, visited: MapSet.new}

parse_op = fn op ->
  do_inc = fn state, n -> %{state | idx: state.idx + n} end
  %{"acc" => fn state, n -> do_inc.(%{state | acc: state.acc + n}, 1) end,
    "jmp" => do_inc, "nop" => fn state, _ -> do_inc.(state, 1) end} |>
  Map.fetch!(op)
end

find_loop = fn lines ->
  Enum.reduce_while(Stream.cycle([1]), init_state, fn _, state ->
    line = Enum.at(lines, state.idx)
    cond do
      MapSet.member?(state.visited, state.idx) -> {:halt, state.acc}
      is_nil(line) -> {:halt, state}
      true ->
        state = %{state | visited: MapSet.put(state.visited, state.idx)}
        {op, arg} = line
        {:cont, parse_op.(op).(state, arg)}
    end
  end)
end

IO.puts("Part 1: #{find_loop.(init_lines)}")


edit_line = fn {op, arg} ->
  case op do
    "acc" -> nil  # no change
    "jmp" -> {"nop", arg}
    "nop" -> {"jmp", arg}
  end
end

find_exit = fn ->
  Enum.reduce_while(0..(length(init_lines) - 1), nil, fn i, _ ->
    newline = edit_line.(Enum.at(init_lines, i))
    if is_nil(newline) do {:cont, nil}
    else
      state = find_loop.(List.replace_at(init_lines, i, newline))
      if is_map(state), do: {:halt, state.acc}, else: {:cont, nil}
    end
  end)
end

IO.puts("Part 2: #{find_exit.()}")
