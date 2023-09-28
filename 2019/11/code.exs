# Solution to Advent of Code 2019, Day 11
# https://adventofcode.com/2019/day/11

Code.require_file("Intcode.ex", "..")  # for prog_step()
Code.require_file("Matrix.ex", "..")  # for print_sparse_map()
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

# We need to update our Intcode computer from Day 9 to await
# inputs (similar to Day 7 Part 2) and combine multiple outputs.
#
# I'm going to abstract the bulk of this code into a module in
# the (probably false) hopes I won't have to modify it again.

run_program = fn state, input ->
  Enum.reduce_while(Stream.cycle([input]), state, fn input, state ->
    {opcode, state} = Intcode.prog_step(input, state)
    case opcode do
      99 -> {:halt, nil}
      4 -> {if(length(state.output) == 2, do: :halt, else: :cont), state}
      _ -> {:cont, state}
    end
  end)
end

init_state = %{pos: 0, nums: data, output: [], r_base: 0}

# We also need to track a grid that is initially zero
# at every point, and some values are changed over time.

init_panel = %{pos: {0,0}, facing: :up, grid: Map.new}

# this changes in Part 2
pos_value_1 = fn panel -> Map.get(panel.grid, panel.pos, 0) end

paint_panel = fn panel, input ->
  %{panel | grid: Map.put(panel.grid, panel.pos, input)}
end

turn_robot = fn panel, input ->
  left  = %{up: :left, left: :down, down: :right, right: :up}
  right = %{up: :right, right: :down, down: :left, left: :up}
  dir = if input == 0, do: left, else: right
  %{panel | facing: dir[panel.facing]}
end

fwd_robot = fn panel ->
  inc_map = %{left: {-1,0}, right: {1,0}, up: {0,-1}, down: {0,1}}
  [{pos_x, pos_y}, {inc_x, inc_y}] = [panel.pos, inc_map[panel.facing]]
  %{panel | pos: {pos_x + inc_x, pos_y + inc_y}}
end

process_output = fn %{output: [color_val, dir_val]}, panel ->
  paint_panel.(panel, color_val) |> turn_robot.(dir_val) |> fwd_robot.()
end

run_robot = fn pos_val_fn ->
  init = {init_state, init_panel}
  Enum.reduce_while(Stream.cycle([1]), init, fn _, {state, panel} ->
    state = run_program.(state, pos_val_fn.(panel))
    if is_nil(state), do: {:halt, panel.grid},
    else: {:cont, {%{state | output: []}, process_output.(state, panel)}}
  end)
end

# now we just need to know how many panels were painted

IO.puts("Part 1: #{run_robot.(pos_value_1) |> map_size}")


pos_value_2 = fn panel ->
  if map_size(panel.grid) == 0, do: 1,
  else: Map.get(panel.grid, panel.pos, 0)
end

decode_image = fn image ->
  Matrix.print_sparse_map(image) |>
  String.replace(["0", "."], " ") |> String.replace("1", "X")
end

IO.puts("Part 2: \n#{run_robot.(pos_value_2) |> decode_image.()}")
