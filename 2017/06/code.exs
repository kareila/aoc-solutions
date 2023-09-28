# Solution to Advent of Code 2017, Day 6
# https://adventofcode.com/2017/day/6

Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

redistribute = fn data ->
  len = map_size(data)
  {i, v} = Enum.max_by(data, fn {_, v} -> v end)
  Enum.reduce(1..v, {i + 1, Map.put(data, i, 0)}, fn _, {i, data} ->
    i = Integer.mod(i, len)
    {i + 1, Map.update!(data, i, &(&1 + 1))}
  end) |> elem(1)
end

inspect_state = fn data -> Enum.map_join(data, ",", &elem(&1,1)) end

data = read_input.() |> hd |> Util.read_numbers |> Util.list_to_map

find_repeat = fn ->
  init_state = %{inspect_state.(data) => 0}
  Enum.reduce_while(Stream.iterate(1, &(&1 + 1)), {init_state, data},
  fn t, {state, data} ->
    data = redistribute.(data)
    s = inspect_state.(data)
    if Map.has_key?(state, s), do: {:halt, {t, state[s]}},
    else: {:cont, {Map.put(state, s, t), data}}
  end)
end

{final, prev} = find_repeat.()

IO.puts("Part 1: #{final}")
IO.puts("Part 2: #{final - prev}")
