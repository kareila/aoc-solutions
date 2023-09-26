# Solution to Advent of Code 2017, Day 23
# https://adventofcode.com/2017/day/23

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# revisiting the code from Day 18
parse_line = fn line ->
  Enum.map(String.split(line), fn v ->
    n = Integer.parse(v, 10)
    if n == :error, do: v, else: elem(n, 0)
  end)
end

lines = read_input.() |> Enum.map(parse_line)

init_state = %{registers: %{}, pos: 0, muls: 0}

out_of_bounds? = fn pos -> pos < 0 or pos >= length(lines) end

rval = fn v, state ->
  if is_integer(v), do: v, else: Map.get(state.registers, v, 0)
end

do_fun = fn [x, y], state, fun ->
  y = fun.(Map.get(state.registers, x, 0), rval.(y, state))
  %{state | registers: Map.put(state.registers, x, y), pos: state.pos + 1}
end

do_set = fn v, state -> do_fun.(v, state, fn _, y -> y end) end
do_sub = fn v, state -> do_fun.(v, state, &-/2) end
do_mul = fn v, state -> do_fun.(v, state, &*/2) end

do_jnz = fn [x, y], state ->
  [x, y] = [rval.(x, state), rval.(y, state)]
  inc = if x != 0, do: y, else: 1
  if inc == 0, do: raise(RuntimeError, "infinite loop detected")
  %{state | pos: state.pos + inc}
end

get_op = fn s ->
  %{"set" => do_set, "sub" => do_sub, "mul" => do_mul, "jnz" => do_jnz} |>
  Map.fetch!(s)
end

step_pt1 = fn state ->
  [op | vals] = Enum.at(lines, state.pos)
  state = if op == "mul", do: %{state | muls: state.muls + 1}, else: state
  get_op.(op).(vals, state)
end

run_program = fn step ->
  Enum.reduce_while(Stream.cycle([1]), init_state, fn _, state ->
    state = step.(state)
    {if(out_of_bounds?.(state.pos), do: :halt, else: :cont), state}
  end)
end

IO.puts("Part 1: #{run_program.(step_pt1).muls}")


is_prime? = fn n ->
  cond do
    not is_integer(n) -> raise(RuntimeError)
    n < 2 -> false
    n in [2, 3] -> true
    true ->
      floored_sqrt = :math.sqrt(n) |> Float.floor |> round
      Enum.all?(2..floored_sqrt, &(rem(n, &1) != 0))
  end
end

# When we get to line 10, instead of doing the loop on d and e,
# just set f=1 if b is a prime number and go to line 24.
step_pt2 = fn state ->
  state = %{state | registers: Map.put_new(state.registers, "a", 1)}
  if state.pos == 10 do
    f = if is_prime?.(state.registers["b"]), do: 1, else: 0
    %{state | registers: Map.put(state.registers, "f", f), pos: 24}
  else
    step_pt1.(state)
  end
end

get_h = fn state -> state.registers["h"] end

IO.puts("Part 2: #{run_program.(step_pt2) |> get_h.()}")
