# Solution to Advent of Code 2017, Day 11
# https://adventofcode.com/2017/day/11

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_input = fn input -> hd(input) |> String.split(",") end

# The first challenge here is to figure out how to represent hexagonal
# tiles in a grid. I've reviewed several possibilities (and adopted others
# in other contexts) but using fractional adjustments keeps things simple.
next_coord = fn dir, {x, y} ->
  case dir do
    "n" -> {x, y - 1}
    "s" -> {x, y + 1}
    "ne" -> {x + 1, y - 0.5}
    "se" -> {x + 1, y + 0.5}
    "nw" -> {x - 1, y - 0.5}
    "sw" -> {x - 1, y + 0.5}
    dir -> raise RuntimeError, "invalid direction #{dir}"
  end
end

walk_path = fn input ->
  Enum.reduce(input, [{0,0}], fn dir, path ->
    [next_coord.(dir, hd(path)) | path]
  end)
end

min_steps = fn stop ->
  Enum.reduce_while(Stream.iterate(0, &(&1 + 1)), {{0,0}, stop},
  fn t, {{x1, y1} = start, {x2, y2}} ->
    if start == stop do {:halt, t}
    else
      {dx, dy} = {x2 - x1, y2 - y1}
      start =
        cond do
          dx > 0 and dy >= 0 -> next_coord.("se", start)
          dx > 0 and dy < 0 -> next_coord.("ne", start)
          dx < 0 and dy >= 0 -> next_coord.("sw", start)
          dx < 0 and dy < 0 -> next_coord.("nw", start)
          dy > 0 -> next_coord.("s", start)
          dy < 0 -> next_coord.("n", start)
        end
      {:cont, {start, stop}}
    end
  end)
end

path = read_input.() |> parse_input.() |> walk_path.() |> Enum.uniq

IO.puts("Part 1: #{hd(path) |> min_steps.()}")


# This probably isn't the most efficient approach, but
# it's plenty fast enough (completes in under a second).
start_task = fn pos -> Task.async(fn -> min_steps.(pos) end) end

all_mins = Enum.map(path, start_task) |> Enum.map(&Task.await/1)

IO.puts("Part 2: #{Enum.max(all_mins)}")
