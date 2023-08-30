# Solution to Advent of Code 2019, Day 9
# https://adventofcode.com/2019/day/9

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_input = fn line ->
  String.split(line, ",") |> Enum.map(&String.to_integer/1)
end

data = read_input.() |> hd |> parse_input.()

# We need to update our Intcode computer from Day 7 to handle
# opcode 9, allow memory expansion, and add a relative base mode.

padded_replace = fn list, pos, val ->
  cond do
    pos < 0 -> raise ArgumentError
    pos < length(list) -> List.replace_at(list, pos, val)
    true -> list ++ List.duplicate(nil, pos - length(list)) ++ [val]
  end
end

parse_opcode = fn nums, pos ->
  [opcode | vals] = Enum.drop(nums, pos)
  {modes, opc} = Integer.digits(opcode) |> Enum.split(-2)
  {Integer.undigits(opc), Enum.reverse(modes), vals}
end

parse_param = fn param, %{nums: nums, modes: modes, r_base: r_base} ->
  Enum.map(param |> Enum.with_index, fn {pos, m_i} ->
    case Enum.at(modes, m_i, 0) do
      0 -> Enum.at(nums, pos, 0)
      1 -> pos
      2 -> Enum.at(nums, pos + r_base, 0)
    end
  end)
end

parse_offset = fn m_i, %{modes: modes, r_base: r_base} ->
  # mode 1 is invalid for offset
  case Enum.at(modes, m_i, 0) do
    0 -> 0
    1 -> raise ArgumentError
    2 -> r_base
  end
end

math_op = fn [pos_i1, pos_i2, pos_out], data, op ->
  [i1, i2] = parse_param.([pos_i1, pos_i2], data)
  pos_out = pos_out + parse_offset.(2, data)
  padded_replace.(data.nums, pos_out, op.(i1, i2))
end

input_op = fn [pos_out], data, input ->
  pos_out = pos_out + parse_offset.(0, data)
  padded_replace.(data.nums, pos_out, input)
end

output_op = fn pos, data ->
  parse_param.(pos, data) |> hd
end

jump_op = fn [pos_t, pos_p], data, cur_pos, op ->
  [t, p] = parse_param.([pos_t, pos_p], data)
  if op.(t, 0), do: p, else: cur_pos
end

bool_op = fn [pos_i1, pos_i2, pos_out], data, op ->
  [i1, i2] = parse_param.([pos_i1, pos_i2], data)
  pos_out = pos_out + parse_offset.(2, data)
  val = if op.(i1, i2), do: 1, else: 0
  padded_replace.(data.nums, pos_out, val)
end

rebase_op = fn pos, data ->
  parse_param.(pos, data) |> hd |> then(&(&1 + data.r_base))
end

prog_step = fn nums, pos, r_base, input, output ->
  {opcode, modes, vals} = parse_opcode.(nums, pos)
  data = %{nums: nums, modes: modes, r_base: r_base}
  case opcode do
    99 -> nil
    1 -> {pos + 4, Enum.take(vals, 3) |> math_op.(data, &+/2), output, r_base}
    2 -> {pos + 4, Enum.take(vals, 3) |> math_op.(data, &*/2), output, r_base}
    3 -> {pos + 2, Enum.take(vals, 1) |> input_op.(data, input), output, r_base}
    4 -> {pos + 2, nums, Enum.take(vals, 1) |> output_op.(data), r_base}
    5 -> {Enum.take(vals, 2) |> jump_op.(data, pos + 3, &!=/2), nums, output, r_base}
    6 -> {Enum.take(vals, 2) |> jump_op.(data, pos + 3, &==/2), nums, output, r_base}
    7 -> {pos + 4, Enum.take(vals, 3) |> bool_op.(data, &</2), output, r_base}
    8 -> {pos + 4, Enum.take(vals, 3) |> bool_op.(data, &==/2), output, r_base}
    9 -> {pos + 2, nums, output, Enum.take(vals, 1) |> rebase_op.(data)}
  end
end

run_program = fn nums, input ->
  Enum.reduce_while(Stream.cycle([input]), {0, nums, nil, 0},
    fn input, {pos, nums, output, r_base} ->
      ret = prog_step.(nums, pos, r_base, input, output)
#      if is_tuple(ret) and output != elem(ret, 2), do: IO.puts(elem(ret, 2))
      if ret == nil, do: {:halt, output}, else: {:cont, ret}
    end)
end

IO.puts("Part 1: #{run_program.(data, 1)}")

IO.puts("Part 2: #{run_program.(data, 2)}")

# elapsed time: approx. 2.5 sec for both parts together
