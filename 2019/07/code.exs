# Solution to Advent of Code 2019, Day 7
# https://adventofcode.com/2019/day/7

Code.require_file("Recurse.ex", ".")  # for permutations()
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

# We need to adjust our Intcode computer from Day 5
# to accept multiple inputs and capture outputs.
#
# Revised code which uses my Intcode module from Day 11.

run_program = fn state, inputs ->
  Enum.reduce_while(Stream.cycle(inputs), state, fn input, state ->
    {opcode, state} = Intcode.prog_step(input, state)
    if opcode == 99, do: {:halt, state.output |> hd},
    else: {:cont, state}
  end)
end

init_state = %{pos: 0, nums: data, output: [], r_base: 0}

setting_combos = Enum.to_list(0..4) |> Recurse.permutations

signals = Enum.map(setting_combos, fn combo ->
  Enum.reduce(combo, 0, fn setting, signal ->
    run_program.(init_state, [setting, signal])
  end)
end)

IO.puts("Part 1: #{Enum.max(signals)}")


# For Part 2, we need long-lived isolated copies of the program
# that can wait for new inputs in a long-running loop.

init_loop = fn combo ->
  Enum.map(combo, fn setting ->
    # the first step is always phase input
    Intcode.prog_step(setting, init_state) |> elem(1)
  end)
end

advance_loop = fn state, input ->
  Enum.reduce_while(Stream.cycle([1]), state, fn _, state ->
    {opcode, state} = Intcode.prog_step(input, state)
    case opcode do
      99 -> {:halt, %{output: state.output}}
      4 -> {:halt, state}
      _ -> {:cont, state}
    end
  end)
end

test_loop = fn combo ->
  Enum.reduce_while(Stream.cycle([1]), init_loop.(combo), fn _, amps ->
    amps = Enum.reduce(amps, [List.last(amps)], fn state, prev ->
      signal_list = hd(prev).output
      curr_signal = if Enum.empty?(signal_list), do: 0, else: List.last(signal_list)
      [advance_loop.(state, curr_signal) | prev]
    end)
    if is_map_key(hd(amps), :nums) do
      {:cont, Enum.take(amps, length(combo)) |> Enum.reverse}
    else
      {:halt, hd(amps).output |> List.last}
    end
  end)
end

setting_combos_2 = Enum.to_list(5..9) |> Recurse.permutations
feedback_signals = Enum.map(setting_combos_2, test_loop)

IO.puts("Part 2: #{Enum.max(feedback_signals)}")
