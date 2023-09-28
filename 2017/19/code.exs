# Solution to Advent of Code 2017, Day 19
# https://adventofcode.com/2017/day/19

Code.require_file("Matrix.ex", "..")
Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

find_start = fn data ->
  Matrix.order_points(data) |> hd |> then(&Map.take(data, &1)) |>
  Util.group_tuples(1, 0) |> Map.fetch!("|") |> hd
end

data = read_input.() |> Matrix.map

init_state = %{pos: find_start.(data), dir: "S", found: ""}

is_step = fn pos -> Map.get(data, pos, " ") != " " end

turn_corner = fn pos, dirs ->
  Util.dir_pos(pos) |> Map.take(dirs) |>
  Enum.find(fn {_, p} -> is_step.(p) end)
end

eval_pos = fn %{pos: pos, dir: dir} = state ->
  state = %{state | pos: Map.fetch!(Util.dir_pos(pos), dir)}
  loc = Map.fetch!(data, pos)
  cond do
    loc == " " -> raise(RuntimeError)  # lost in space
    loc in ["-", "|"] -> state
    loc != "+" -> %{state | found: state.found <> loc}
    dir in ["W", "E"] ->  # must turn north or south
      {nxt_d, nxt_p} = turn_corner.(pos, ["N", "S"])
      %{state | dir: nxt_d, pos: nxt_p}
    dir in ["N", "S"] ->  # must turn east or west
      {nxt_d, nxt_p} = turn_corner.(pos, ["W", "E"])
      %{state | dir: nxt_d, pos: nxt_p}
  end
end

walk_path =
  Enum.reduce_while(Stream.iterate(0, &(&1 + 1)), init_state, fn t, state ->
    if is_step.(state.pos), do: {:cont, eval_pos.(state)},
    else: {:halt, {state.found, t}}
  end)

IO.puts("Part 1: #{elem(walk_path, 0)}")
IO.puts("Part 2: #{elem(walk_path, 1)}")
