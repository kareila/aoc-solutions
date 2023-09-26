# Solution to Advent of Code 2017, Day 19
# https://adventofcode.com/2017/day/19

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# parses input as a grid of values
matrix = fn lines ->
  for {line, y} <- Enum.with_index(lines),
      {v, x} <- String.graphemes(line) |> Enum.with_index,
  do: {x, y, v}
end

matrix_map = fn matrix ->
  for {x, y, v} <- matrix, into: %{}, do: { {x, y}, v }
end

adj_pos = fn {x, y} -> [{x - 1, y}, {x + 1, y}, {x, y - 1}, {x, y + 1}] end

# returns a list of rows
order_points = fn grid ->
  List.keysort(grid, 0) |> Enum.group_by(&elem(&1,1)) |>
  Map.to_list |> List.keysort(0) |> Enum.map(&elem(&1,1))
end

find_start = fn data ->
  Map.keys(data) |> order_points.() |> hd |> then(&Map.take(data, &1)) |>
  Enum.group_by(&elem(&1,1), &elem(&1,0)) |> Map.fetch!("|") |> hd
end

data = read_input.() |> matrix.() |> matrix_map.()

init_state = %{pos: find_start.(data), dir: "S", found: ""}

dir_pos = fn pos -> Enum.zip(~w(W E N S), adj_pos.(pos)) |> Map.new end
is_step = fn pos -> Map.get(data, pos, " ") != " " end

turn_corner = fn pos, dirs ->
  Map.take(dir_pos.(pos), dirs) |> Enum.find(fn {_, p} -> is_step.(p) end)
end

eval_pos = fn %{pos: pos, dir: dir} = state ->
  state = %{state | pos: Map.fetch!(dir_pos.(pos), dir)}
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
