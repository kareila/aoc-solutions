# Solution to Advent of Code 2019, Day 19
# https://adventofcode.com/2019/day/19

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

# Each of these calculations is independent, so we can parallelize.
start_task = fn input, data ->
  Task.async(fn -> run_program.(input, data) end)
end

task_result = fn task -> Task.await(task).output |> hd end

scan_beam = fn data ->
  for i <- 0..49, j <- 0..49 do [i, j] end |>
  Enum.map(&start_task.(&1, data)) |> Enum.map(task_result) |> Enum.sum
end

IO.puts("Part 1: #{scan_beam.(data)}")


# Okay, I had a wild and exciting time debugging Part 2 on this one.
# Turns out that my original run_program code acted like it was using {y,x}
# instead of {x,y} here, because I was naively cycling the inputs, but they
# were being processed on cycles 2 and 21. Before I figured that out, I
# implemented at least 5 different methods of calculating the square and
# kept getting the same backwards answer! For Part 1, the reversal was
# irrelevant due to symmetry. After correcting the inputs, I had to reverse
# the square calculation subroutines from my original version as well.

get_val = fn x, y -> run_program.([x, y], data).output |> hd end

seek = fn y, x, v ->
  Enum.reduce_while(Stream.iterate(y, &(&1 + 1)), nil, fn y, _ ->
    if get_val.(x, y) == v, do: {:cont, nil}, else: {:halt, y - v}
  end)
end

find_edge = fn x, y -> {x, seek.(y, x, 0) |> seek.(x, 1)} end

# Starting at 699,699 is a time saving measure, YMMV...
# Do be careful not to scan too close to 0,0 in any case.

find_square = fn ->
  Enum.reduce_while(Stream.cycle([1]), find_edge.(699, 699), fn _, {x, y} ->
    if get_val.(x + 99, y - 99) == 1, do: {:halt, {x, y - 99}},
    else: {:cont, find_edge.(x + 1, y)}
  end)
end

{sq_x, sq_y} = find_square.()

IO.puts("Part 2: #{10000 * sq_x + sq_y}")

# elapsed time: approx. 1.5 sec for both parts together
