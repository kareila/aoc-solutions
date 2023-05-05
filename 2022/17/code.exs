# Solution to Advent of Code 2022, Day 17
# https://adventofcode.com/2022/day/17

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

rock_values = [
"""
..####.
""",
"""
...#...
..###..
...#...
""",
"""
....#..
....#..
..###..
""",
"""
..#....
..#....
..#....
..#....
""",
"""
..##...
..##...
""",
] |> Enum.map(&String.split(&1, "\n", trim: true))

rocks = %{index: 0, width: 7, vals: rock_values, shifted: 0, dropped: 0}
rocks = Map.put(rocks, :size, length(rocks.vals))

jets = %{index: 0, vals: hd(read_input.()) |> String.graphemes}
jets = Map.put(jets, :size, length(jets.vals))

# Cycle detection: at some point the jet pattern will repeat, and we can
# skip ahead. Since the first cycle starts from a flat surface, we only
# count levels the second time. (Used in Part 2.)

data = %{rows: %{}, rocks: rocks, jets: jets, cycle: nil, skip_ahead: false}

# A map of lists seems to be faster than just a map or just lists.
point_value = fn {x, y}, data ->
  Map.get(data.rows, y, []) |> Enum.at(x)
end

set_value = fn {x, y}, v, data ->
  cond do
    x < 0 or x >= data.rocks.width -> raise(ArgumentError)
    Map.has_key?(data.rows, y) ->
      row = List.replace_at(data.rows[y], x, v)
      %{data | rows: Map.put(data.rows, y, row)}
    true -> raise(ArgumentError)
  end
end

can_go? = fn data, point, limit? ->
  cond do
    limit? -> false    # floor or wall
    point_value.(point, data) == "#" -> false   # rock
    true -> true
  end
end

can_go_down? = fn {x, y}, data -> can_go?.(data, {x, y - 1}, y <= 0) end

can_go_left? = fn {x, y}, data -> can_go?.(data, {x - 1, y}, x <= 0) end

can_go_right? = fn {x, y}, data ->
  can_go?.(data, {x + 1, y}, x >= data.rocks.width - 1)
end

scan_current_rock = fn data ->
  rock_index = Integer.mod(data.rocks.index, data.rocks.size)
  Enum.at(data.rocks.vals, rock_index)
  |> Enum.map(&String.graphemes/1) |> Enum.reverse
end

field_height = fn data -> map_size(data.rows) end

new_rock = fn data ->
  next_y = field_height.(data)
  # add 3 empty rows
  rows = for j <- 0..2, into: data.rows,
    do: {next_y + j, List.duplicate(".", data.rocks.width)}
  # convert the string pattern into array values, building up from y=0
  rows = for {row, j} <- scan_current_rock.(data) |> Enum.with_index(3),
    into: rows, do: {next_y + j, row}
  %{data | rows: rows}
end

# compile some attributes that describe the current rock
rock_data = fn data ->
  r = scan_current_rock.(data)
  h = length(r) - 1  # y value of top of rock
  t = field_height.(data) - data.rocks.dropped - 1   # y value of top edge
  shifted = data.rocks.shifted
  
  {left_edge, right_edge} = Enum.reduce(r, {[], []}, fn row, {le, re} ->
    l = Enum.find_index(row, &(&1 == "#"))
    le = [l + shifted | le]
    r = Enum.reverse(row) |> Enum.find_index(&(&1 == "#"))
    re = [data.rocks.width - 1 - r + shifted | re]
    {le, re}
  end)

  # THE SECOND (+) ROCK HAS BOTTOM EDGES IN THE MIDDLE...
  col = Enum.at(r, 0) |> Enum.with_index
  mid = Enum.at(r, 1, [])

  bottom_edge = Enum.reduce(col, [], fn {c, i}, be ->
    cond do
      c == "#" -> [{0, i + shifted} | be]
      Enum.empty?(mid) -> be
      Enum.at(mid, i) != "#" -> be
      true -> [{1, i + shifted} | be]
    end
  end) |> Enum.reverse

  %{h: h, t: t, b: bottom_edge, l: left_edge, r: right_edge}
end

shift_ok? = fn data, edges, side, can_go?, caller ->
  Enum.reduce(0..edges.h, true, fn i, ok ->
    p = {Enum.at(side, i), edges.t - i}
    if point_value.(p, data) != "#",
      do: raise(RuntimeError, "Something went wrong in #{caller}")
    ok and can_go?.(p, data)
  end)
end

do_shift = fn data, edges, update, d ->
  data = Enum.reduce(0..edges.h, data, fn i, data ->
    [left, right] = [Enum.at(edges.l, i), Enum.at(edges.r, i)]
    update.(data, left, right, edges.t - i)
  end)
  %{data | rocks: %{data.rocks | shifted: data.rocks.shifted + d}}
end

shift_rock_left = fn data ->
  # how to update the position values
  update = fn data, left, right, y ->
    # move the left edge one space to the left
    data = set_value.({left - 1, y}, "#", data)
    # there is now a space where the right edge was
    set_value.({right, y}, ".", data)
  end
  # can every point on the left edge move left?
  edges = rock_data.(data)
  ok = shift_ok?.(data, edges, edges.l, can_go_left?, "shift_rock_left")
  if ok, do: do_shift.(data, edges, update, -1), else: data
end

shift_rock_right = fn data ->
  # how to update the position values
  update = fn data, left, right, y ->
    # move the right edge one space to the right
    data = set_value.({right + 1, y}, "#", data)
    # there is now a space where the left edge was
    set_value.({left, y}, ".", data)
  end
  # can every point on the right edge move right?
  edges = rock_data.(data)
  ok = shift_ok?.(data, edges, edges.r, can_go_right?, "shift_rock_right")
  if ok, do: do_shift.(data, edges, update, 1), else: data
end

move_rock_down = fn data ->
  edges = rock_data.(data)
  top = edges.t
  y = top - edges.h   # location of bottom row of rock

  # can every point on the bottom edge move down?
  ok = Enum.reduce(edges.b, true, fn {offset, x}, ok ->
    p = {x, y + offset}
    if point_value.(p, data) != "#",
      do: raise(RuntimeError, "Something went wrong in move_rock_down")
    ok and can_go_down?.(p, data)
  end)

  if ok do
    rows = scan_current_rock.(data) |> Enum.zip(y..top)
    # update the position values (for the entire rock, not just the edges)
    data = Enum.reduce(rows, data, fn {row, j}, data ->
      Enum.with_index(row, data.rocks.shifted) |>
      Enum.filter(&(elem(&1,0) == "#")) |> Enum.map(&elem(&1,1)) |>
      Enum.reduce(data, fn x, data ->
        if point_value.({x, j}, data) != "#",
          do: raise(RuntimeError, "Something went wrong in move_rock_down")
        data = set_value.({x, j}, ".", data)
        set_value.({x, j - 1}, "#", data)
      end)
    end)
    data = %{data | rocks: %{data.rocks | dropped: data.rocks.dropped + 1}}
    # we need to know if this moved successfully
    {true, data}
  else
    {false, data}
  end
end

cycle_update = fn data ->
  data = %{data | jets: %{data.jets | index: 0}}  # loop the pattern
  # store cycle info if we don't have it yet
  cond do
    data.skip_ahead -> data
    data.cycle == nil ->
      %{data | cycle: {data.rocks.index, field_height.(data)}}
    true ->
      {step, height} = data.cycle
      cycle = {data.rocks.index - step, field_height.(data) - height}
      %{data | cycle: cycle, skip_ahead: true}
  end
end

jet_action = fn data ->
  data = if data.jets.index < data.jets.size,
         do: data, else: cycle_update.(data)
  jet = Enum.at(data.jets.vals, data.jets.index)
  data = %{data | jets: %{data.jets | index: data.jets.index + 1}}
  case jet do
    "<" -> shift_rock_left.(data)
    ">" -> shift_rock_right.(data)
    jet -> raise(RuntimeError, "Invalid jet value #{jet}")
  end
end

rock_drop = fn data ->
  # drop as far as we can
  data = Enum.reduce_while(Stream.cycle([1]), new_rock.(data), fn _, data ->
    {moved, data} = jet_action.(data) |> move_rock_down.()
    if moved, do: {:cont, data}, else: {:halt, data}
  end)
  # remove dead airspace
  y_range = Stream.iterate(field_height.(data) - 1, &(&1 - 1))
  drop_rows = Enum.reduce_while(y_range, [], fn y, drop_rows ->
    if data.rows[y] |> Enum.all?(&(&1 == ".")),
    do: {:cont, [y | drop_rows]}, else: {:halt, drop_rows}
  end)
  data = %{data | rows: Map.drop(data.rows, drop_rows)}
  # reset for next rock
  rocks = %{data.rocks | index: data.rocks.index + 1}
  %{data | rocks: %{rocks | shifted: 0, dropped: 0}}
end

data = Enum.reduce(1..2022, data, fn _, data -> rock_drop.(data) end)

IO.puts("Part 1: #{field_height.(data)}")


simulate = fn num, data ->
  data = Enum.reduce_while(Stream.cycle([1]), data, fn _, data ->
    data = rock_drop.(data)
    if data.skip_ahead, do: {:halt, data}, else: {:cont, data}
  end)

  {steps_per_cycle, levels_per_cycle} = data.cycle
  skipped_n = div(num, steps_per_cycle) - 2  # we already did 2 cycles
  skip = steps_per_cycle * skipped_n + data.rocks.index
  rest = num - skip  # how many steps are left after the last cycle completes
  data = Enum.reduce(1..rest, data, fn _, data -> rock_drop.(data) end)
  
  # return what we need to know
  skipped_n * levels_per_cycle + field_height.(data)
end

IO.puts("Part 2: #{simulate.(1_000_000_000_000, data)}")
