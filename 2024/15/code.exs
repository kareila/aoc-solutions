# Solution to Advent of Code 2024, Day 15
# https://adventofcode.com/2024/day/15

Code.require_file("Matrix.ex", "..")
Code.require_file("Util.ex", "..")

# returns TWO lists of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |>  String.split("\n\n") |>
  Enum.map(&String.split(&1, "\n", trim: true))
end

parse_input = fn [grid, moves] ->
  grid = Matrix.grid(grid) |> Matrix.map
  moves = Enum.flat_map(moves, &String.graphemes/1)
  [pos] = Util.group_tuples(grid, 1, 0) |> Map.fetch!("@")
  %{grid: grid, moves: moves, pos: pos}
end

input = read_input.() |> parse_input.()


next_pos = fn {x, y}, dir ->
  %{"<" => {x - 1, y}, "^" => {x, y - 1},
    ">" => {x + 1, y}, "v" => {x, y + 1}} |> Map.fetch!(dir)
end

# construct the line of points to be acted on by the robot this turn
get_line = fn %{grid: grid, moves: moves, pos: pos} ->
  Enum.reduce_while(Stream.cycle([1]), {pos, []}, fn _, {loc, line} ->
    if Map.fetch!(grid, loc) in ["#", "."], do: {:halt, line},
    else: {:cont, {next_pos.(loc, hd(moves)), [loc | line]}}
  end)
end

# shift this tile if the space for it is empty
do_move = fn {p, tile}, grid, dir ->
  next = next_pos.(p, dir)
  if Map.fetch!(grid, next) != ".", do: grid,
  else: Map.put(grid, next, tile) |> Map.put(p, ".")
end

# execute all movement for this turn
next_state = fn %{grid: grid, moves: moves, pos: pos}, l_fn, m_fn ->
  line = l_fn.(%{grid: grid, moves: moves, pos: pos}) |>
         Enum.map(fn k -> {k, Map.fetch!(grid, k)} end)
  nxt_g = Enum.reduce(line, grid, &m_fn.(&1, &2, hd(moves)))
  [nxt_p] = Util.group_tuples(nxt_g, 1, 0) |> Map.fetch!("@")
  if nxt_p == pos, do: %{grid: grid, moves: tl(moves), pos: pos},
  else: %{grid: nxt_g, moves: tl(moves), pos: nxt_p}
end

do_all_moves = fn data ->
  nst = fn _, d -> next_state.(d, get_line, do_move) end
  Enum.reduce(data.moves, data, nst)
end

gps_boxes = fn %{grid: grid}, box ->
  Util.group_tuples(grid, 1, 0) |> Map.fetch!(box) |>
  Enum.map(fn {x, y} -> 100 * y + x end) |> Enum.sum
end

IO.puts("Part 1: #{do_all_moves.(input) |> gps_boxes.("O")}")

widen_map = fn %{grid: grid, moves: moves} ->
  grid =
    Matrix.print_map(grid) |> String.replace("#", "##") |>
    String.replace("O", "[]") |> String.replace(".", "..") |>
    String.replace("@", "@.") |> String.split("\n", trim: true)
  parse_input.([grid, moves])
end

get_wide_line = fn %{grid: grid, moves: moves, pos: pos} ->
  line = get_line.(%{grid: grid, moves: moves, pos: pos})
  if length(line) == 1 or hd(moves) in ["<", ">"] do line
  else  # also check parallel columns spanned by a single box
    Enum.map(line, fn k -> {k, Map.fetch!(grid, k)} end) |>
    Enum.flat_map(fn {p, tile} ->
      case tile do
        "[" -> [next_pos.(p, ">")]
        "]" -> [next_pos.(p, "<")]
        _ -> []
      end
    end) |> then(&{line, &1})
  end
end

# collate all points from various lines that could be pushed this turn
# (looping here avoids using recursion in get_wide_line)
expand_lines = fn d ->
  Enum.reduce_while(Stream.cycle([1]), {[d], []}, fn _, {todo, done} ->
    if Enum.empty?(todo) do
      case hd(d.moves) do
        "<" -> Enum.sort_by(done, &{elem(&1, 0), elem(&1, 1)}, :asc)
        ">" -> Enum.sort_by(done, &{elem(&1, 0), elem(&1, 1)}, :desc)
        "^" -> Enum.sort_by(done, &{elem(&1, 1), elem(&1, 0)}, :asc)
        "v" -> Enum.sort_by(done, &{elem(&1, 1), elem(&1, 0)}, :desc)
      end |> Enum.reject(fn p -> d.grid[p] == "]" end) |> then(&{:halt, &1})
    else
      [d | todo] = todo
      line = get_wide_line.(d)
      if is_tuple(line) do
        {line, add} = line
        add = Enum.reject(add, & &1 in done) |> Enum.map(& %{d | pos: &1})
        {:cont, {add ++ todo, Enum.uniq(line ++ done)}}
      else
        {:cont, {todo, Enum.uniq(line ++ done)}}
      end
    end
  end)
end

do_wide_move = fn {p, tile}, grid, dir ->
  move =
    if tile != "[" do [{p, tile}]
    else  # add back the associated "]" tile we removed in expand_lines
      q = next_pos.(p, ">")
      if dir == ">", do: [{q, Map.fetch!(grid, q)}, {p, tile}],
      else: [{p, tile}, {q, Map.fetch!(grid, q)}]
    end
  next = Enum.map(move, fn {k, _} -> Map.fetch!(grid, next_pos.(k, dir)) end)
  blocked? =
    if dir in ["<", ">"], do: hd(next) != ".",
    else: Enum.any?(next, & &1 != ".")
  if blocked? do grid
  else
    Enum.reduce(move, grid, fn {k, v}, grid ->
      Map.put(grid, next_pos.(k, dir), v) |> Map.put(k, ".")
    end)
  end
end

do_all_wide = fn data ->
  nst = fn _, d -> next_state.(d, expand_lines, do_wide_move) end
  Enum.reduce(data.moves, data, nst)
end

IO.puts("Part 2: #{widen_map.(input) |> do_all_wide.() |> gps_boxes.("[")}")

# elapsed time: approx. 11.5 sec for both parts together
