# Solution to Advent of Code 2019, Day 5
# https://adventofcode.com/2019/day/5

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_input = fn line ->
  String.split(line, ",") |> Enum.map(&String.to_integer/1)
end

data = read_input.() |> hd |> parse_input.()

# We need to rewrite our Intcode computer from Day 2 to
# accept a variable number of parameters (not just chunks of 4).
# It also uses extended opcodes to allow for literal numeric inputs.
# Opcodes 5-8 are only used in Part 2.

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
  parse_param.(pos, nums, modes) |> hd |> IO.puts
  nums
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

prog_step = fn nums, pos, input ->
  {opcode, modes, vals} = parse_opcode.(nums, pos)
  case opcode do
    99 -> nil
    1 -> {pos + 4, Enum.take(vals, 3) |> math_op.(nums, modes, &+/2)}
    2 -> {pos + 4, Enum.take(vals, 3) |> math_op.(nums, modes, &*/2)}
    3 -> {pos + 2, Enum.take(vals, 1) |> input_op.(nums, input)}
    4 -> {pos + 2, Enum.take(vals, 1) |> output_op.(nums, modes)}
    5 -> {Enum.take(vals, 2) |> jump_op.(nums, modes, pos + 3, &!=/2), nums}
    6 -> {Enum.take(vals, 2) |> jump_op.(nums, modes, pos + 3, &==/2), nums}
    7 -> {pos + 4, Enum.take(vals, 3) |> bool_op.(nums, modes, &</2)}
    8 -> {pos + 4, Enum.take(vals, 3) |> bool_op.(nums, modes, &==/2)}
  end
end

run_program = fn nums, input ->
  Enum.reduce_while(Stream.cycle([input]), {0, nums}, fn input, {pos, nums} ->
    ret = prog_step.(nums, pos, input)
    if ret == nil, do: {:halt, nums}, else: {:cont, ret}
  end)
end

run_program.(data, 1)
IO.puts("Part 1 complete.\n")

run_program.(data, 5)
IO.puts("Part 2 complete.")
