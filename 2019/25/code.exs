# Solution to Advent of Code 2019, Day 25
# https://adventofcode.com/2019/day/25

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

# I decided I'd rather have fun playing the game manually
# to figure out the necessary actions than spend a lot of
# time working on an automated exploration algorithm.

dronescript = File.read!("script.txt") |> String.to_charlist

run_program = fn input, data ->
  init_state = %{pos: 0, nums: data, output: [], r_base: 0, input: input}
  Enum.reduce_while(Stream.cycle([1]), init_state, fn _, state ->
    input = if length(state.input) > 0, do: hd(state.input), else: nil
    {opcode, state} = Intcode.prog_step(input, state)
    case opcode do
      3 -> if input, do: {:cont, %{state | input: tl(state.input)}},
                     else: {:halt, state}
      99 -> {:halt, state}
      _ -> {:cont, state}
    end
  end)
end

IO.puts(run_program.(dronescript, data).output)

# There is no Part 2!  Merry Christmas!
