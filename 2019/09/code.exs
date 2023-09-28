# Solution to Advent of Code 2019, Day 9
# https://adventofcode.com/2019/day/9

Code.require_file("Intcode.ex", "..")  # for prog_step()
Code.require_file("Util.ex", "..")  # for list_to_map()

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_input = fn line ->
  String.split(line, ",") |> Enum.map(&String.to_integer/1)
end

data = read_input.() |> hd |> parse_input.() |> Util.list_to_map

# We need to update our Intcode computer from Day 7 to handle
# opcode 9, allow memory expansion, and add a relative base mode.
#
# Revised code which uses my Intcode module from Day 11.

run_program = fn state, input ->
  Enum.reduce_while(Stream.cycle([input]), state, fn input, state ->
    {opcode, state} = Intcode.prog_step(input, state)
    if opcode == 99, do: {:halt, state.output |> hd},
    else: {:cont, state}
  end)
end

init_state = %{pos: 0, nums: data, output: [], r_base: 0}

IO.puts("Part 1: #{run_program.(init_state, 1)}")
IO.puts("Part 2: #{run_program.(init_state, 2)}")
