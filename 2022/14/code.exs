# Solution to Advent of Code 2022, Day 14
# https://adventofcode.com/2022/day/14

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

all_matches = fn str, pat ->
  Regex.scan(pat, str, capture: :all_but_first) |> Enum.concat
end

# return a list of points to be added to the set
parse_line = fn l ->
  points = all_matches.(l, ~r"\b(\d+,\d+)\b")
  Enum.zip(points, points |> tl)
end

map_rocks = fn lines ->
  # connect the lines between each pair of points
  Enum.flat_map(lines, parse_line) |> Enum.flat_map(fn {start, stop} ->
    [x1, y1, x2, y2] = Enum.flat_map([start, stop], &String.split(&1, ","))
                    |> Enum.map(&String.to_integer/1)  # argh
    if x1 == x2 do
      Enum.map(y1..y2, fn y -> {x1, y, "r"} end)  # "r" for rock
    else
      Enum.map(x1..x2, fn x -> {x, y1, "r"} end)  # "r" for rock
    end
  end)
end

# we don't actually need the value, that's just for debugging purposes
# (also, using MapSet instead of Map is slightly slower, not much but some)
can_step? = fn grid, y, x -> not Map.has_key?(grid, {x, y + 1}) end

next_step = fn {x,y}, grid ->
  cond do
    can_step?.(grid, y, x + 0) -> x + 0
    can_step?.(grid, y, x - 1) -> x - 1
    can_step?.(grid, y, x + 1) -> x + 1
    true -> nil
  end
end

grid = read_input.() |> map_rocks.()
max_y = Enum.map(grid, &elem(&1,1)) |> Enum.max
grid_map = for {x, y, v} <- grid, into: %{}, do: { {x, y}, v }

do_sand = fn grid_map, fn_halt? ->
  entry = [500, 0]  # point at which sand is entering the room
  Enum.reduce_while(Stream.iterate(0, &(&1 + 1)), grid_map, fn step, grid ->
    [x, y] = Enum.reduce_while(Stream.cycle([1]), entry, fn _, [x, y] ->
      cond do
        fn_halt?.(y) -> {:halt, entry}
        y == max_y + 1 -> {:halt, [x, y]}  # floor for Part 2
        next_x = next_step.({x,y}, grid) -> {:cont, [next_x, y + 1]}
        true -> {:halt, [x, y]}
      end
    end)
    if [x, y] == entry, do: {:halt, [step, grid]},  # entry point blocked
    else: {:cont, Map.put(grid, {x,y}, "s")}  # "s" for sand
  end)
end

[steps1, grid_map] = do_sand.(grid_map, fn y -> y == max_y end)

IO.puts("Part 1: #{steps1}")


# We can pick up where we left off with a different exit condition.
# We have to add one so that the entry blockage counts as a step.
[steps2, _] = do_sand.(grid_map, fn _ -> false end)

IO.puts("Part 2: #{steps1 + steps2 + 1}")
