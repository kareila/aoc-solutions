# Solution to Advent of Code 2019, Day 7
# https://adventofcode.com/2019/day/7

require Recurse  # for permutations()

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_input = fn line ->
  String.split(line, ",") |> Enum.map(&String.to_integer/1)
end

data = read_input.() |> hd |> parse_input.()

# We need to adjust our Intcode computer from Day 5
# to accept multiple inputs and capture outputs.

parse_opcode = fn nums, pos ->
  [opcode | vals] = Enum.drop(nums, pos)
  {modes, opc} = Integer.digits(opcode) |> Enum.split(-2)
  {Integer.undigits(opc), Enum.reverse(modes), vals}
end

parse_param = fn param, nums, modes ->
  Enum.map(param |> Enum.with_index, fn {pos, m_i} ->
    if Enum.at(modes, m_i, 0) == 1, do: pos, else: Enum.at(nums, pos)
  end)
end

math_op = fn [pos_i1, pos_i2, pos_out], nums, modes, op ->
  [i1, i2] = parse_param.([pos_i1, pos_i2], nums, modes)
  List.replace_at(nums, pos_out, op.(i1, i2))
end

input_op = fn [pos_out], nums, input ->
  List.replace_at(nums, pos_out, input)
end

output_op = fn pos, nums, modes ->
  parse_param.(pos, nums, modes) |> hd
end

jump_op = fn [pos_t, pos_p], nums, modes, cur_pos, op ->
  [t, p] = parse_param.([pos_t, pos_p], nums, modes)
  if op.(t, 0), do: p, else: cur_pos
end

bool_op = fn [pos_i1, pos_i2, pos_out], nums, modes, op ->
  [i1, i2] = parse_param.([pos_i1, pos_i2], nums, modes)
  val = if op.(i1, i2), do: 1, else: 0
  List.replace_at(nums, pos_out, val)
end

prog_step = fn nums, pos, input, output ->
  {opcode, modes, vals} = parse_opcode.(nums, pos)
  case opcode do
    99 -> nil
    1 -> {pos + 4, Enum.take(vals, 3) |> math_op.(nums, modes, &+/2), output}
    2 -> {pos + 4, Enum.take(vals, 3) |> math_op.(nums, modes, &*/2), output}
    3 -> {pos + 2, Enum.take(vals, 1) |> input_op.(nums, input), output}
    4 -> {pos + 2, nums, Enum.take(vals, 1) |> output_op.(nums, modes)}
    5 -> {Enum.take(vals, 2) |> jump_op.(nums, modes, pos + 3, &!=/2), nums, output}
    6 -> {Enum.take(vals, 2) |> jump_op.(nums, modes, pos + 3, &==/2), nums, output}
    7 -> {pos + 4, Enum.take(vals, 3) |> bool_op.(nums, modes, &</2), output}
    8 -> {pos + 4, Enum.take(vals, 3) |> bool_op.(nums, modes, &==/2), output}
  end
end

run_program = fn nums, inputs ->
  Enum.reduce_while(Stream.cycle(inputs), {0, nums, nil},
    fn input, {pos, nums, output} ->
      ret = prog_step.(nums, pos, input, output)
      if ret == nil, do: {:halt, output}, else: {:cont, ret}
    end)
end

setting_combos = Enum.to_list(0..4) |> Recurse.permutations

signals = Enum.map(setting_combos, fn combo ->
  Enum.reduce(combo, 0, fn setting, signal ->
    run_program.(data, [setting, signal])
  end)
end)

IO.puts("Part 1: #{Enum.max(signals)}")


# For Part 2, we need long-lived isolated copies of the program
# that can wait for new inputs in a long-running loop.

init_loop = fn combo ->
  Enum.map(combo, fn setting ->
    # the first step is always phase input
    {pos, nums, _} = prog_step.(data, 0, setting, nil)
    %{pos: pos, nums: nums, lastout: 0}
  end)
end

advance_loop = fn data, input ->
  Enum.reduce_while(Stream.cycle([1]), data, fn _, data ->
    %{pos: pos, nums: nums, lastout: output} = data
    {opcode, modes, vals} = parse_opcode.(nums, pos)
    case opcode do
      99 -> {:halt, %{lastout: output}}
      1 -> {:cont, %{data | pos: pos + 4, nums: Enum.take(vals, 3)
                          |> math_op.(nums, modes, &+/2)}}
      2 -> {:cont, %{data | pos: pos + 4, nums: Enum.take(vals, 3)
                          |> math_op.(nums, modes, &*/2)}}
      3 -> {:cont, %{data | pos: pos + 2, nums: Enum.take(vals, 1)
                          |> input_op.(nums, input)}}
      4 -> {:halt, %{data | pos: pos + 2, lastout: Enum.take(vals, 1)
                          |> output_op.(nums, modes)}}
      5 -> {:cont, %{data | pos: Enum.take(vals, 2)
                          |> jump_op.(nums, modes, pos + 3, &!=/2)}}
      6 -> {:cont, %{data | pos: Enum.take(vals, 2)
                          |> jump_op.(nums, modes, pos + 3, &==/2)}}
      7 -> {:cont, %{data | pos: pos + 4, nums: Enum.take(vals, 3)
                          |> bool_op.(nums, modes, &</2)}}
      8 -> {:cont, %{data | pos: pos + 4, nums: Enum.take(vals, 3)
                          |> bool_op.(nums, modes, &==/2)}}
    end
  end)
end

test_loop = fn combo ->
  Enum.reduce_while(Stream.cycle([1]), init_loop.(combo), fn _, amps ->
    amps = Enum.reduce(amps, [List.last(amps)], fn data, prev ->
      signal = hd(prev).lastout
      [advance_loop.(data, signal) | prev]
    end)
    if is_map_key(hd(amps), :nums) do
      {:cont, Enum.take(amps, length(combo)) |> Enum.reverse}
    else
      {:halt, hd(amps).lastout}
    end
  end)
end

setting_combos_2 = Enum.to_list(5..9) |> Recurse.permutations
feedback_signals = Enum.map(setting_combos_2, test_loop)

IO.puts("Part 2: #{Enum.max(feedback_signals)}")
