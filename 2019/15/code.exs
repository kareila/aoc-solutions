# Solution to Advent of Code 2019, Day 15
# https://adventofcode.com/2019/day/15

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

init_state = %{pos: 0, nums: data, output: [], r_base: 0, loc: [{0,0}]}

run_program = fn input, state ->
  state = %{state | output: []}
  Enum.reduce_while(Stream.cycle([input]), state, fn input, state ->
    {opcode, state} = Intcode.prog_step(input, state)
    if opcode != 4 do {:cont, state}  # infinite loop - don't check for 99
    else
      {px, py} = hd(state.loc)
      new_loc =
        case input do
          1 -> {px, py - 1}
          2 -> {px, py + 1}
          3 -> {px - 1, py}
          4 -> {px + 1, py}
        end
      if new_loc in state.loc do
        {:halt, %{state | output: [0]}}
      else
        {:halt, %{state | loc: [new_loc | state.loc]}}
      end
    end
  end)
end

winner =
  Enum.reduce_while(Stream.cycle([1]), [init_state], fn _, [state | queue] ->
    adv = Enum.map(1..4, &run_program.(&1, state)) |>
          Enum.reject(&(&1.output == [0]))
    oxy = Enum.filter(adv, &(&1.output == [2]))
    if length(oxy) == 0, do: {:cont, queue ++ adv}, else: {:halt, hd(oxy)}
  end)

IO.puts("Part 1: #{length(winner.loc) - 1}")


oxy_state = %{winner | loc: [hd(winner.loc)],  output: []}

fill_all =
  Enum.reduce_while(Stream.cycle([1]), [oxy_state], fn _, queue ->
    adv =
      Enum.flat_map(queue, fn state ->
        Enum.map(1..4, &run_program.(&1, state)) |>
        Enum.reject(&(&1.output == [0]))
      end)
    if length(adv) > 0, do: {:cont, adv}, else: {:halt, hd(queue)}
  end)


IO.puts("Part 2: #{length(fill_all.loc) - 1}")
