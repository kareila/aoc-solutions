# Solution to Advent of Code 2019, Day 2
# https://adventofcode.com/2019/day/2

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_input = fn line ->
  String.split(line, ",") |> Enum.map(&String.to_integer/1)
end

prog_step = fn nums, pos ->
  [opcode | vals] = Enum.drop(nums, pos * 4) |> Enum.take(4)
  if opcode not in [1,2,99], do: raise(ArgumentError)
  if opcode == 99 do nil
  else
    [pos_i1, pos_i2, pos_out] = vals
    op = if opcode == 1, do: &+/2, else: &*/2
    [i1, i2] = [Enum.at(nums, pos_i1), Enum.at(nums, pos_i2)]
    result = op.(i1, i2)
    List.replace_at(nums, pos_out, result)
  end
end

run_program = fn nums ->
  Enum.reduce_while(Stream.iterate(0, &(&1 + 1)), nums, fn pos, nums ->
    ret = prog_step.(nums, pos)
    if ret == nil, do: {:halt, Enum.at(nums, 0)}, else: {:cont, ret}
  end)
end

# before running the program, replace position 1 with 12 and position 2 with 2

alter_input = fn p1, p2 ->
  read_input.() |> hd |> parse_input.()
  |> List.replace_at(1, p1) |> List.replace_at(2, p2)
end

result = alter_input.(12, 2) |> run_program.()

IO.puts("Part 1: #{result}")


# now we need to try all combinations of inputs from 0 to 99
# and halt when we find the inputs that give us 19690720

inputs = for i <- 0..99, j <- 0..99, do: {i,j}
[noun, verb] =
  Enum.reduce_while(inputs, 19690720, fn {i,j}, target ->
    result = alter_input.(i, j) |> run_program.()
    if result == target, do: {:halt, [i,j]}, else: {:cont, target}
  end)

IO.puts("Part 2: #{100 * noun + verb}")
