# Solution to Advent of Code 2021, Day 11
# https://adventofcode.com/2021/day/11

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

matrix = fn lines ->
  for {line, y} <- Enum.with_index(lines),
      {v, x} <- String.graphemes(line) |> Enum.with_index,
  do: {x, y, String.to_integer(v)}
end

matrix_map = fn matrix ->
  for {x, y, v} <- matrix, into: %{}, do: { {x, y}, v }
end

process_flash = fn init_state ->
  Enum.reduce_while(Stream.cycle([1]), init_state, fn _, state ->
    %{data: data, has_flashed: has_flashed} = state
    next = Enum.flat_map(data, fn {p, v} -> if v > 9, do: [p], else: [] end)
    if Enum.empty?(next) do {:halt, state}
    else
      {x, y} = hd(next)
      data = Map.put(data, {x, y}, 0)
      has_flashed = MapSet.put(has_flashed, {x, y})
      # increase the level of all surrounding un-flashed points by 1
      data = for(i <- (x - 1)..(x + 1), j <- (y - 1)..(y + 1), pos = {i, j},
                 is_map_key(data, pos), do: {pos, data[pos]}) |>
        Enum.reject(fn {p, _} -> MapSet.member?(has_flashed, p) end) |>
        Enum.reduce(data, fn {p, v}, data -> Map.put(data, p, v + 1) end)
      {:cont, %{data: data, has_flashed: has_flashed}}
    end
  end)
end

do_step = fn data ->
  # First, the energy level of each octopus increases by 1.
  data = Map.new(data, fn {{x, y}, v} -> {{x, y}, v + 1} end)
  # Then, any octopus with an energy level greater than 9 flashes.
  %{data: data, has_flashed: MapSet.new} |> process_flash.()
end

init_data = read_input.() |> matrix.() |> matrix_map.()

count_flashes = fn steps ->
  Enum.map_reduce(1..steps, init_data, fn _, data ->
    %{data: data, has_flashed: has_flashed} = do_step.(data)
    {MapSet.size(has_flashed), data}
  end)
end

{num_flashes, data} = count_flashes.(100)

IO.puts("Part 1: #{Enum.sum(num_flashes)}")


last_step =  # pick up where we left off after 100 steps
  Enum.reduce_while(Stream.iterate(101, &(&1 + 1)), data, fn t, data ->
    %{data: data, has_flashed: has_flashed} = do_step.(data)
    if MapSet.size(has_flashed) == map_size(data),
    do: {:halt, t}, else: {:cont, data}
  end)

IO.puts("Part 2: #{last_step}")
