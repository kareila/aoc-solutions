# Solution to Advent of Code 2017, Day 18
# https://adventofcode.com/2017/day/18

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_line = fn line ->
  Enum.map(String.split(line), fn v ->
    n = Integer.parse(v, 10)
    if n == :error, do: v, else: elem(n, 0)
  end)
end

lines = read_input.() |> Enum.map(parse_line)

init_state = %{registers: %{}, pos: 0, snd: nil}

out_of_bounds? = fn pos -> pos < 0 or pos >= length(lines) end

rval = fn v, state ->
  if is_integer(v), do: v, else: Map.get(state.registers, v, 0)
end

# snd & rcv do different things in Part 2
do_snd = fn [y], state ->
  state = %{state | pos: state.pos + 1}
  if Map.has_key?(state, :snd), do: %{state | snd: rval.(y, state)},
  else: {rval.(y, state), %{state | sent: state.sent + 1}}
end

do_rcv1 = fn [y], state ->
  state = %{state | pos: state.pos + 1}
  if rval.(y, state) != 0, do: {state.snd, state}, else: state
end

do_rcv2 = fn [y], state ->
  if Enum.empty?(state.queue) do
    %{state | wait: true}  # pos does not advance
  else
    if is_integer(y), do: raise(RuntimeError, "not a register")
    state = %{state | wait: false, pos: state.pos + 1}
    [val | queue] = state.queue
    %{state | registers: Map.put(state.registers, y, val), queue: queue}
  end
end

do_rcv = fn v, state ->
  if(Map.has_key?(state, :snd), do: do_rcv1, else: do_rcv2).(v, state)
end

# these 4 are fundamentally identical
do_fun = fn [x, y], state, fun ->
  y = fun.(Map.get(state.registers, x, 0), rval.(y, state))
  %{state | registers: Map.put(state.registers, x, y), pos: state.pos + 1}
end

do_set = fn v, state -> do_fun.(v, state, fn _, y -> y end) end
do_add = fn v, state -> do_fun.(v, state, &+/2) end
do_mul = fn v, state -> do_fun.(v, state, &*/2) end
do_mod = fn v, state -> do_fun.(v, state, &Integer.mod/2) end

do_jgz = fn [x, y], state ->
  [x, y] = [rval.(x, state), rval.(y, state)]
  inc = if x > 0, do: y, else: 1
  if inc == 0, do: raise(RuntimeError, "infinite loop detected")
  %{state | pos: state.pos + inc}
end

get_op = fn s ->
  %{"snd" => do_snd, "set" => do_set, "add" => do_add, "mul" => do_mul,
    "mod" => do_mod, "rcv" => do_rcv, "jgz" => do_jgz} |> Map.fetch!(s)
end

step_program = fn state ->
  [op | vals] = Enum.at(lines, state.pos)
  get_op.(op).(vals, state)
end

run_program = fn ->
  Enum.reduce_while(Stream.cycle([1]), init_state, fn _, state ->
    state = step_program.(state)
    cond do
      is_tuple(state) -> {:halt, elem(state, 0)}
      out_of_bounds?.(state.pos) -> raise(RuntimeError, "out of bounds")
      true -> {:cont, state}
    end
  end)
end

IO.puts("Part 1: #{run_program.()}")


init_duet =
  %{0 => %{registers: %{"p" => 0}, pos: 0, sent: 0, queue: [], wait: false},
    1 => %{registers: %{"p" => 1}, pos: 0, sent: 0, queue: [], wait: false}}

blocked? = fn state -> state.wait and Enum.empty?(state.queue) end

queue_add = fn state, v ->
  if is_nil(v), do: state, else: %{state | queue: state.queue ++ [v]}
end

queue_transfer = fn state0, state1 ->
  {send1, state0} = if is_tuple(state0), do: state0, else: {nil, state0}
  {send0, state1} = if is_tuple(state1), do: state1, else: {nil, state1}
  %{0 => queue_add.(state0, send0), 1 => queue_add.(state1, send1)}
end

run_duet = fn ->
  Enum.reduce_while(Stream.cycle([1]), init_duet, fn _, duet ->
    if blocked?.(duet[0]) and blocked?.(duet[1]) do {:halt, duet}
    else
      duet = queue_transfer.(step_program.(duet[0]), step_program.(duet[1]))
      if out_of_bounds?.(duet[0].pos) or out_of_bounds?.(duet[1].pos),
      do: {:halt, duet}, else: {:cont, duet}
    end
  end) |> Map.fetch!(1) |> Map.fetch!(:sent)
end

IO.puts("Part 2: #{run_duet.()}")
