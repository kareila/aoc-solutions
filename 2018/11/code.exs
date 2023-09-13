# Solution to Advent of Code 2018, Day 11
# https://adventofcode.com/2018/day/11

# no input file today
serial_no = 2694
grid_size = 300

power_level = fn {x, y} ->
  rack_id = x + 10
  level = rack_id * y + serial_no
  level = level * rack_id
  Integer.digits(level) |> Enum.at(-3, 0) |> then(&(&1 - 5))
end

power_vals =
  for i <- 1 .. grid_size, j <- 1 .. grid_size, into: %{} do
    {{i, j}, power_level.({i, j})}
  end

square_level = fn {x, y}, n, cache ->
  cond do
    n == 1 -> Map.fetch!(power_vals, {x, y})
    Map.has_key?(cache, {x, y, n}) -> Map.fetch!(cache, {x, y, n})
    n > 3 ->
      h_edge = Enum.reduce(x .. (x + n - 1), 0, fn i, tot ->
        tot + Map.fetch!(power_vals, {i, (y + n - 1)}) end)
      v_edge = Enum.reduce(y .. (y + n - 2), 0, fn j, tot ->
        tot + Map.fetch!(power_vals, {(x + n - 1), j}) end)
      h_edge + v_edge + Map.fetch!(cache, {x, y, n - 1})
    true ->
      for i <- x .. (x + n - 1), j <- y .. (y + n - 1), reduce: 0 do
        tot -> tot + Map.fetch!(power_vals, {i, j})
      end
  end
end

find_square = fn n, cache ->
  {vals, cache} =
    for x <- 1 .. grid_size - n + 1, y <- 1 .. grid_size - n + 1 do {x, y} end |>
    Enum.map_reduce(cache, fn {x, y}, cache ->
      val = square_level.({x, y}, n, cache)
      {{x, y, n, val}, Map.put(cache, {x, y, n}, val)}
    end)
  Enum.max_by(vals, &elem(&1, 3)) |> put_elem(3, cache)
end

{x3, y3, _, _} = find_square.(3, %{})

IO.puts("Part 1: #{x3},#{y3}")


find_mega = fn limit ->
  {_, best} =
    Enum.reduce(1..limit, {%{}, %{}}, fn n, {cache, best} ->
      {x, y, n, cache} = find_square.(n, cache)
      {cache, Map.put(best, {x, y, n}, cache[{x, y, n}])}
    end)
  Map.keys(best) |> Enum.max_by(&(best[&1]))
end

# saving time by stopping at size 20 instead of going all the way to 300 (YMMV)
{max_x, max_y, max_n} = find_mega.(20)

IO.puts("Part 2: #{max_x},#{max_y},#{max_n}")

# elapsed time: approx. 4.5 sec for both parts together
