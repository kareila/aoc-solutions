# Solution to Advent of Code 2019, Day 21
# https://adventofcode.com/2019/day/21

require Intcode  # for prog_step()

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_input = fn line ->
  String.split(line, ",") |> Enum.map(&String.to_integer/1)
end

data = read_input.() |> hd |> parse_input.()

# this is equivalent to !(A & B & C) & D, or (!A & D) | (!B & D) | (!C & D)
springscript = """
NOT A J
NOT J J
AND B J
AND C J
NOT J J
AND D J
WALK
""" |> String.to_charlist

run_program = fn input, data ->
  init_state = %{pos: 0, nums: data, output: [], r_base: 0, input: input}
  Enum.reduce_while(Stream.cycle([1]), init_state, fn _, state ->
    input = if length(state.input) > 0, do: hd(state.input), else: nil
    {opcode, state} = Intcode.prog_step(input, state)
    case opcode do
      3 -> {:cont, %{state | input: tl(state.input)}}
      99 -> {:halt, state}
      _ -> {:cont, state}
    end
  end)
end

runspring = run_program.(springscript, data)

IO.puts("Part 1: #{List.last(runspring.output)}")


# this is equivalent to (!A & D) | (!B & D) | (!C & D & H),
# or (!A | !B | (!C & H)) & D
springscript = """
NOT C J
AND H J
NOT B T
OR T J
NOT A T
OR T J
AND D J
RUN
""" |> String.to_charlist

runspring = run_program.(springscript, data)

IO.puts("Part 2: #{List.last(runspring.output)}")

# elapsed time: approx. 10 sec for both parts together
