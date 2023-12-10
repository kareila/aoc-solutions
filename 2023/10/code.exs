# Solution to Advent of Code 2023, Day 10
# https://adventofcode.com/2023/day/10

Code.require_file("Matrix.ex", "..")
Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

grid = read_input.() |> Matrix.map

# calculate relative direction using difference between tuple values
t_dist = fn tup1, tup2 ->
  Enum.map([tup1, tup2], &Tuple.to_list/1) |>
  Enum.zip_with(fn [t1, t2] -> t1 - t2 end)
end

# name directional difference values for easier reading
facing = %{n: [0, -1], s: [0, 1], w: [-1, 0], e: [1, 0]}

can_connect? = fn {to_p, to_v}, {from_p, from_v} ->
  pipes = %{n: ~w(S | L J), s: ~w(S | 7 F), w: ~w(S - J 7), e: ~w(S - L F)}
  %{facing.n => from_v in pipes.n and to_v in pipes.s,
    facing.s => from_v in pipes.s and to_v in pipes.n,
    facing.w => from_v in pipes.w and to_v in pipes.e,
    facing.e => from_v in pipes.e and to_v in pipes.w} |>
  Map.get(t_dist.(to_p, from_p))
end

# "every pipe in the main loop connects to its two neighbors"
check_pos = fn {from_p, from_v} ->
  c = Map.take(grid, Util.adj_pos(from_p)) |>
      Enum.filter(&can_connect?.(&1, {from_p, from_v}))
  if length(c) == 2, do: c, else: raise RuntimeError
end

# calculate the actual value of the start tile
start_tile = fn {s, _}, pipes ->
  %{[facing.w, facing.n] => "J", [facing.w, facing.s] => "7",
    [facing.w, facing.e] => "-", [facing.n, facing.s] => "|",
    [facing.n, facing.e] => "L", [facing.s, facing.e] => "F"} |>
  Map.get(Enum.map(pipes, fn {p, _} -> t_dist.(p, s) end) |> Enum.sort)
end

adjust_start = fn [start | path] ->
  pipes = [List.first(path), List.last(path)]
  [put_elem(start, 1, start_tile.(start, pipes)) | path]
end

walk_loop = fn ->
  start = Map.to_list(grid) |> List.keyfind!("S", 1)
  [first, last] = check_pos.(start)
  Enum.reduce_while(Stream.cycle([1]), [first, start], fn _, path ->
    [curr, prev] = Enum.take(path, 2)
    [next] = check_pos.(curr) -- [prev]
    if next != last, do: {:cont, [next | path]},
    else: {:halt, Enum.reverse([last | path])}
  end)
end

loop = walk_loop.() |> adjust_start.() |> Map.new

IO.puts("Part 1: #{map_size(loop) |> div(2)}")


rows = Map.keys(grid) |> Util.group_tuples(1) |> Map.values

# use odd/even # of loop crossings to determine inside/outside;
# simplify by only counting pipes pointing in the same direction
# (F7 and LJ count as two, while FJ and L7 count as one)
traverse_row = fn row ->
  validate = fn {s, t} -> if s, do: raise(RuntimeError), else: t end
  Enum.reduce(Enum.sort(row), {false, 0}, fn p, {inside, tot} ->
    cond do
      not is_map_key(loop, p) -> {inside, tot + if(inside, do: 1, else: 0)}
      loop[p] in ~w(| J L) -> {not inside, tot}
      true -> {inside, tot}
    end
  end) |> validate.()
end

IO.puts("Part 2: #{Enum.map(rows, traverse_row) |> Enum.sum}")
