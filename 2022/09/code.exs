# Solution to Advent of Code 2022, Day 9
# https://adventofcode.com/2022/day/9

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

init_visited = fn -> MapSet.new( [{0,0}] ) end

# list of points from head to tail, minimum 2
init_snake = fn len -> List.duplicate({0,0}, len) end

# only track the position of the tail
mark_visited = fn v, snake -> MapSet.put(v, List.last(snake)) end

move = fn {x, y}, dir ->
  n = %{ "L" => {-1, 0}, "R" => {1, 0}, "D" => {0, -1}, "U" => {0, 1} }
  {nx, ny} = n[dir]
  {x + nx, y + ny}
end

choose_dir = fn tail, xy, d_gt, d_lt ->
  cond do
    xy.t > xy.h -> move.(tail, d_gt)
    xy.t < xy.h -> move.(tail, d_lt)
    true -> tail
  end
end

  # move left or right as needed
move_lr = fn tail, x -> choose_dir.(tail, x, "L", "R") end

  # move up or down as needed
move_ud = fn tail, y -> choose_dir.(tail, y, "D", "U") end

update = fn {snake, visited}, segment, dir ->
  [head, tail] = Enum.slice(snake, segment, 2)
  # the head moves, all other segments just react
  head = if(segment != 0, do: head, else: move.(head, dir))
  [{head_x, head_y}, {tail_x, tail_y}] = [head, tail]
  [x, y] = [%{t: tail_x, h: head_x}, %{t: tail_y, h: head_y}]
  # any valid move ends in 'x' or 'y' (but not both) being no more than 2 away
  tail = cond do
    head_y - 2 == tail_y -> move_lr.(tail, x) |> move.("U")
    head_y + 2 == tail_y -> move_lr.(tail, x) |> move.("D")
    head_x + 2 == tail_x -> move_ud.(tail, y) |> move.("L")
    head_x - 2 == tail_x -> move_ud.(tail, y) |> move.("R")
    true -> tail
  end
  # update the snake with new head and tail values
  snake = List.replace_at(snake, segment + 0, head)
  snake = List.replace_at(snake, segment + 1, tail)
  # return a tuplet with updated values
  {snake, mark_visited.(visited, snake)}
end

parse_input = fn lines ->
  Enum.map(lines, fn l ->
    [dir, num_str] = String.split(l)
    {dir, String.to_integer(num_str)}
  end)
end

do_move = fn {dir, num_moves}, num_seg, data ->
  Enum.reduce(1..num_moves, data, fn _, data ->
    Enum.reduce(1..num_seg, data, fn s, data ->
      update.(data, s - 1, dir)
    end)
  end)
end

do_moves = fn input, sz ->
  init = {init_snake.(sz), init_visited.()}
  Enum.reduce(input, init, fn move, data ->
    do_move.(move, sz - 1, data)  # one move per "joint" between segments
  end) |> elem(1)
end

visited = read_input.() |> parse_input.() |> do_moves.(2)

IO.puts("Part 1: #{MapSet.size(visited)}")


visited = read_input.() |> parse_input.() |> do_moves.(10)

IO.puts("Part 2: #{MapSet.size(visited)}")
