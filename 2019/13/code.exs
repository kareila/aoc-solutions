# Solution to Advent of Code 2019, Day 13
# https://adventofcode.com/2019/day/13

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

run_program = fn data, input ->
  state = %{pos: 0, nums: data, output: [], r_base: 0}
  Enum.reduce_while(Stream.cycle([input]), state, fn input, state ->
    {opcode, state} = Intcode.prog_step(input, state)
    if opcode == 99, do: {:halt, state.output}, else: {:cont, state}
  end)
end

tile_vals = fn output -> Enum.drop(output, 2) |> Enum.take_every(3) end

num_blocks = fn vals -> Enum.count(vals, &(&1 == 2)) end

tiles = run_program.(data, nil) |> tile_vals.()

IO.puts("Part 1: #{num_blocks.(tiles)}")


new_game = Map.put(data, 0, 2)

eval_move = fn x, px ->
  cond do
    x > px -> 1
    x < px -> -1
    true -> 0
  end
end

eval_output = fn game, state ->
  if length(state.output) < 3 do %{game | state: state}
  else
    [x, y, tile] = state.output
    game = %{game | state: %{state | output: []}}
    cond do
      {x,y} == {-1,0} -> %{game | score: tile}
      tile == 3 ->  %{game | px: x}
      tile == 4 -> %{game | input: eval_move.(x, game.px)}
      true -> game
    end
  end
end

play_game = fn data ->
  state = %{pos: 0, nums: data, output: [], r_base: 0}
  game = %{state: state, input: 0, score: 0, px: nil}
  Enum.reduce_while(Stream.cycle([1]), game, fn _, game ->
    {opcode, state} = Intcode.prog_step(game.input, game.state)
    case opcode do
      99 -> {:halt, game.score}
      4 -> {:cont, eval_output.(game, state)}
      _ -> {:cont, %{game | state: state}}
    end
  end)
end

IO.puts("Part 2: #{play_game.(new_game)}")

# elapsed time: approx. 10 sec for both parts together
