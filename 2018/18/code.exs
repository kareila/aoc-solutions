# Solution to Advent of Code 2018, Day 18
# https://adventofcode.com/2018/day/18

Code.require_file("Matrix.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
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
  Map.keys(data) |> Map.new(fn p -> {p, next_val.(p, data)} end)
end

resource_value = fn data ->
  w = Enum.count(data, fn {_, v} -> v == "|" end)
  l = Enum.count(data, fn {_, v} -> v == "#" end)
  w * l
end

tick_minutes = fn data, num ->
  Enum.reduce(1..num, data, fn _, data -> tick.(data) end)
end

data = read_input.() |> Matrix.map

ten = tick_minutes.(data, 10)

IO.puts("Part 1: #{resource_value.(ten)}")


cycle_minutes = fn data, num ->
  info =
    Enum.reduce_while(0..num, {data, %{}}, fn t, {data, snapshots} ->
      snap = Matrix.print_map(data)
      if Map.has_key?(snapshots, snap) do
        {:halt, {data, t - snapshots[snap], t}}
      else
        {:cont, {tick.(data), Map.put(snapshots, snap, t)}}
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
