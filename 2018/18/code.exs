# Solution to Advent of Code 2018, Day 18
# https://adventofcode.com/2018/day/18

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# parses input as a grid of values
matrix = fn lines ->
  for {line, y} <- Enum.with_index(lines),
      {v, x} <- String.graphemes(line) |> Enum.with_index,
  do: {x, y, v}
end

matrix_map = fn matrix ->
  for {x, y, v} <- matrix, into: %{}, do: { {x, y}, v }
end

order_points = fn grid ->
  List.keysort(grid, 0) |> Enum.group_by(&elem(&1,1)) |>
  Map.to_list |> List.keysort(0) |> Enum.map(&elem(&1,1))
end

count_adj_type = fn {x, y}, type, data ->
  [{x - 1, y - 1}, {x - 1, y}, {x - 1, y + 1}, {x, y - 1},
   {x + 1, y - 1}, {x + 1, y}, {x + 1, y + 1}, {x, y + 1}] |>
  then(&Map.take(data, &1)) |> Enum.count(fn {_, v} -> v == type end)
end

next_val = fn {x, y}, data ->
  num = fn c -> count_adj_type.({x, y}, c, data) end
  case Map.fetch!(data, {x, y}) do
    "." -> if num.("|") > 2, do: "|", else: "."
    "|" -> if num.("#") > 2, do: "#", else: "|"
    "#" -> if num.("#") > 0 and num.("|") > 0, do: "#", else: "."
  end
end

tick = fn data ->
  Enum.reduce(Map.keys(data), %{}, fn p, nxt ->
    Map.put(nxt, p, next_val.(p, data))
  end)
end

resource_value = fn data ->
  w = Enum.count(data, fn {_, v} -> v == "|" end)
  l = Enum.count(data, fn {_, v} -> v == "#" end)
  w * l
end

tick_minutes = fn data, num ->
  Enum.reduce(1..num, data, fn _, data -> tick.(data) end)
end

data = read_input.() |> matrix.() |> matrix_map.()

ten = tick_minutes.(data, 10)

IO.puts("Part 1: #{resource_value.(ten)}")


snapshot = fn data ->
  Enum.map_join(order_points.(Map.keys(data)), "\n", fn row ->
    Enum.map_join(List.keysort(row, 0), &Map.fetch!(data, &1))
  end)
end

cycle_minutes = fn data, num ->
  info =
    Enum.reduce_while(1..num, {data, %{}}, fn t, {data, snapshots} ->
      data = tick.(data)
      snap = snapshot.(data)
      if Map.has_key?(snapshots, snap) do
        {:halt, {data, t - snapshots[snap], t}}
      else
        {:cont, {data, Map.put(snapshots, snap, t)}}
      end
    end)
  if tuple_size(info) == 2 do elem(info, 0)  # loop completed
  else
    {data, repeat, t} = info
    #IO.inspect("cycle of length #{repeat} detected at #{t}")
    t =
      Enum.reduce_while(Stream.cycle([repeat]), t, fn p, t ->
        if t + p > num, do: {:halt, t + 1}, else: {:cont, t + p}
      end)
    Enum.reduce(t..num, data, fn _, data -> tick.(data) end)
  end
end

big = cycle_minutes.(data, 1_000_000_000)

IO.puts("Part 2: #{resource_value.(big)}")

# elapsed time: approx. 3 sec for both parts together
