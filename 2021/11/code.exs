# Solution to Advent of Code 2021, Day 11
# https://adventofcode.com/2021/day/11

Code.require_file("Matrix.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

int_vals = fn {p, v} -> {p, String.to_integer(v)} end

# increase the level of all surrounding un-flashed points by 1
increase_neighbors = fn {x, y}, data, has_flashed ->
  for i <- (x - 1)..(x + 1), j <- (y - 1)..(y + 1), pos = {i, j},
      is_map_key(data, pos), pos not in has_flashed, into: %{},
  do: {pos, data[pos] + 1}
end

process_flash = fn pos, %{data: data, has_flashed: has_flashed} ->
  has_flashed = [pos | has_flashed]
  data = Map.merge(data, increase_neighbors.(pos, data, has_flashed))
  %{data: Map.put(data, pos, 0), has_flashed: has_flashed}
end

check_for_flashes = fn init_state ->
  Enum.reduce_while(Stream.cycle([1]), init_state, fn _, state ->
    next = Map.filter(state.data, fn {_, v} -> v > 9 end) |> Map.keys
    if Enum.empty?(next), do: {:halt, state},
    else: {:cont, process_flash.(hd(next), state)}
  end)
end

do_step = fn data ->
  # First, the energy level of each octopus increases by 1.
  data = Map.new(data, fn {{x, y}, v} -> {{x, y}, v + 1} end)
  # Then, any octopus with an energy level greater than 9 flashes.
  %{data: data, has_flashed: []} |> check_for_flashes.()
end

init_data = read_input.() |> Matrix.map |> Map.new(int_vals)

count_flashes = fn steps ->
  Enum.map_reduce(1..steps, init_data, fn _, data ->
    %{data: data, has_flashed: has_flashed} = do_step.(data)
    {length(has_flashed), data}
  end)
end

{num_flashes, data} = count_flashes.(100)

IO.puts("Part 1: #{Enum.sum(num_flashes)}")


last_step =  # pick up where we left off after 100 steps
  Enum.reduce_while(Stream.iterate(101, &(&1 + 1)), data, fn t, data ->
    %{data: data, has_flashed: has_flashed} = do_step.(data)
    if length(has_flashed) == map_size(data),
    do: {:halt, t}, else: {:cont, data}
  end)

IO.puts("Part 2: #{last_step}")
