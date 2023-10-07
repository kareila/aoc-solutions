# Solution to Advent of Code 2021, Day 17
# https://adventofcode.com/2021/day/17

Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_input = fn line ->
  # values of x are always positive; values of y are always negative
  [x1, x2, y1, y2] = Util.read_numbers(line)
  %{tx_min: x1, tx_max: x2, ty_min: y1, ty_max: y2}
end

target = read_input.() |> hd |> parse_input.()

# our max_y can be calculated purely from our initial y velocity
max_y = fn n -> div(n * (n + 1), 2) end

# this must be true, because math
IO.puts("Part 1: #{max_y.(target.ty_min)}")


in_target_area? = fn {x, y} ->
  cond do
    x < target.tx_min or x > target.tx_max -> false
    y < target.ty_min or y > target.ty_max -> false
    true -> true
  end
end

# y limit is the "minimum" because the target is below us
past_target_area? = fn {x, y} ->
  x > target.tx_max or y < target.ty_min
end

# we never use negative x velocities, but all values trend to zero
time_step = fn [{vx, vy}, {px, py}] ->
  nvx = if vx > 0, do: vx - 1, else: 0
  [{nvx, vy - 1}, {px + vx, py + vy}]
end

check_trajectory = fn vx, vy ->
  init = [{vx, vy}, {0, 0}]
  Enum.reduce_while(Stream.cycle([1]), init, fn _, [prev_v, prev_p] ->
    [next_v, next_p] = time_step.([prev_v, prev_p])
    if past_target_area?.(next_p), do: {:halt, prev_p},
    else: {:cont, [next_v, next_p]}
  end)
end

# map out our search space based on parameter limits:
# - x velocity must be >= 1 and <= tx_max
# - y velocity must be >= ty_min and <= neg ty_min (see Part 1)
count_hits = fn ->
  for x <- 1..target.tx_max, y <- target.ty_min..(0 - target.ty_min)
  do check_trajectory.(x, y) end |> Enum.count(in_target_area?)
end

IO.puts("Part 2: #{count_hits.()}")
