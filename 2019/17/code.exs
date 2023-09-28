# Solution to Advent of Code 2019, Day 17
# https://adventofcode.com/2019/day/17

Code.require_file("Intcode.ex", "..")
Code.require_file("Util.ex", "..")
Code.require_file("Matrix.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_input = fn line ->
  String.split(line, ",") |> Enum.map(&String.to_integer/1)
end

data = read_input.() |> hd |> parse_input.() |> Util.list_to_map

run_program = fn data ->
  init_state = %{pos: 0, nums: data, output: [], r_base: 0}
  Enum.reduce_while(Stream.cycle([1]), init_state, fn input, state ->
    {opcode, state} = Intcode.prog_step(input, state)
    if opcode == 99, do: {:halt, state}, else: {:cont, state}
  end)
end

parse_ascii = fn ascii ->
  List.to_string(ascii) |> String.split("\n", trim: true) |> Matrix.map
end

list_intersections = fn data ->
  Enum.filter(Map.keys(data), fn pos ->
    [pos | Util.adj_pos(pos)] |> Enum.all?(&Map.get(data, &1, ".") == "#")
  end)
end

point_sum = fn list -> Enum.map(list, &Tuple.product/1) |> Enum.sum end

ascii = run_program.(data).output
ascii |> IO.puts
total = parse_ascii.(ascii) |> list_intersections.() |> point_sum.()

IO.puts("Part 1: #{total}")


# I don't see an obvious way to solve Part 2 programmatically?
# Need to examine the given grid and figure out a set of 3 short
# instructions that can visit every scaffold point at least once.
#
# A. L6 R12 L6
# B. R12 L10 L4 L6
# C. L10 L10 L4 L6
#
# A, B, A, B, A, C, B, C, A, C

data = Map.put(data, 0, 2)

# Honestly, after giving up on solving the movement with code, I also
# still spent plenty of time figuring out how to format the input.

path_code = ["A,B,A,B,A,C,B,C,A,C\n", "L,6,R,12,L,6\n",
  "R,12,L,10,L,4,L,6\n", "L,10,L,10,L,4,L,6\n", "n\n"] |>
  # have to use one long list of ascii integers
  Enum.flat_map(&String.to_charlist/1)

walk_path = fn input, data ->
  init = {input, %{pos: 0, nums: data, output: [], r_base: 0}}
  Enum.reduce_while(Stream.cycle([1]), init, fn _, {input, state} ->
    {opcode, state} = List.first(input) |> Intcode.prog_step(state)
    case opcode do
      99 -> {:halt, state}
#     4 ->
#        IO.puts(state.output)
#        {:cont, {input, %{state | output: []}}}
      3 -> {:cont, {tl(input), state}}
      _ -> {:cont, {input, state}}
    end
  end)
end

result = walk_path.(path_code, data).output |> List.last

IO.puts("Part 2: #{result}")
