# Solution to Advent of Code 2019, Day 11
# https://adventofcode.com/2019/day/11

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_input = fn line ->
  String.split(line, ",") |> Enum.map(&String.to_integer/1)
end

data = read_input.() |> hd |> parse_input.()

# We need to update our Intcode computer from Day 9 to await
# inputs (similar to Day 7 Part 2) and combine multiple outputs.
#
# I'm going to abstract the bulk of this code into a module in
# the (probably false) hopes I won't have to modify it again.

require Intcode  # for prog_step()

run_program = fn state, input ->
  Enum.reduce_while(Stream.cycle([input]), state, fn input, state ->
    {opcode, state} = Intcode.prog_step(input, state)
    case opcode do
      99 -> {:halt, nil}
      4 -> if length(state.output) == 2, do: {:halt, state}, else: {:cont, state}
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
  {pos_x, pos_y} = panel.pos
  {inc_x, inc_y} = inc_map[panel.facing]
  %{panel | pos: {pos_x + inc_x, pos_y + inc_y}}
end

process_output = fn %{output: [color_val, dir_val]}, panel ->
  paint_panel.(panel, color_val) |> turn_robot.(dir_val) |> fwd_robot.()
end

run_robot = fn pos_val_fn ->
  init = {init_state, init_panel}
  Enum.reduce_while(Stream.cycle([1]), init, fn _, {state, panel} ->
    input = pos_val_fn.(panel)
    state = run_program.(state, input)
    if state == nil do {:halt, panel.grid}
    else
      panel = process_output.(state, panel)
      state = %{state | output: []}
      {:cont, {state, panel}}
    end
  end)
end

# now we just need to know how many panels were painted

IO.puts("Part 1: #{run_robot.(pos_value_1) |> map_size}")


pos_value_2 = fn panel ->
  if map_size(panel.grid) == 0, do: 1,
  else: Map.get(panel.grid, panel.pos, 0)
end

decode_image = fn image ->
  pts = Enum.group_by(image, &elem(&1,1), &elem(&1,0)) |> Map.get(1)
  {x_min, x_max} = Enum.map(pts, &elem(&1,0)) |> Enum.min_max
  {y_min, y_max} = Enum.map(pts, &elem(&1,1)) |> Enum.min_max
  Enum.map_join(y_min..y_max, "\n", fn y ->
    Range.new(x_min - 1, x_max) |>
    Enum.map_join("", fn x -> Map.get(image, {x,y}, 0) end)
  end) |>
  String.replace("0", " ") |> String.replace("1", "X")
end

IO.puts("Part 2: \n#{run_robot.(pos_value_2) |> decode_image.()}")
