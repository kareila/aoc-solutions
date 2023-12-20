# Solution to Advent of Code 2023, Day 17
# https://adventofcode.com/2023/day/17

Code.require_file("Matrix.ex", "..")
Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

grid = read_input.() |> Matrix.map |>
       Map.new(fn {k, v} -> {k, String.to_integer(v)} end)

{x_min, x_max, y_min, y_max} = Matrix.limits(grid)
[start, finish] = [{x_min, y_min}, {x_max, y_max}]

init = %{0 => [%{path: [start], dir: [], loss: 0}]}

take_step = fn %{path: path, dir: dir, loss: loss}, limits ->
  {x, y} = hd(path)
  straight = Enum.take(dir, 1) |>
             Enum.map(fn {dx, dy} -> {x + dx, y + dy} end)
  opts =
    cond do
      length(dir) == 0 -> Util.adj_pos({x, y})
      length(dir) < limits.min -> straight
      length(dir) == limits.max -> Util.adj_pos({x, y}) -- straight
      true -> Util.adj_pos({x, y})
    end |> Enum.reject(&(&1 in path)) |> Enum.filter(&is_map_key(grid, &1))
  has_min_steps? =
    limits.min == 1 or finish in straight and length(dir) >= (limits.min - 1)
  if finish in opts and has_min_steps? do loss + Map.fetch!(grid, finish)
  else
    Enum.map(opts, fn {i, j} ->
      nxt = {i - x, j - y}
      dir = if nxt != List.first(dir), do: [nxt], else: [nxt | dir]
      %{path: [{i, j}, {x, y}], dir: dir,
        loss: loss + Map.fetch!(grid, {i, j})}
    end)
  end
end

step_next = fn {nxt, state}, limits ->
  data = take_step.(nxt, limits)
  if is_integer(data) do data
  else
    Enum.group_by(data, &{hd(&1.path), hd(&1.dir), length(&1.dir)}) |>
    Enum.map(fn {k, v} -> {k, Enum.min_by(v, &(&1.loss))} end) |>
    Enum.reduce({[], state}, fn {k, v}, {list, state} ->
      prev = Map.get(state, k)
      if not is_nil(prev) and v.loss >= prev, do: {list, state},
      else: {[{v.loss, v} | list], Map.put(state, k, v.loss)}
    end)
  end
end

update_pq = fn {v, d}, pq -> Map.update(pq, v, [d], &[d | &1]) end

minimize_loss = fn data, limits ->
  Enum.reduce_while(Stream.cycle([1]), {data, %{}}, fn _, {pq, state} ->
    {[nxt | rest], pq} = Map.keys(pq) |> Enum.min |> then(&Map.pop!(pq, &1))
    pq = if Enum.empty?(rest), do: pq, else: Map.put(pq, nxt.loss, rest)
    result = step_next.({nxt, state}, limits)
    if is_integer(result) do {:halt, result}
    else
      {list, state} = result
      {:cont, {Enum.reduce(list, pq, update_pq), state}}
    end
  end)
end

IO.puts("Part 1: #{minimize_loss.(init, %{min: 1, max: 3})}")
IO.puts("Part 2: #{minimize_loss.(init, %{min: 4, max: 10})}")

# elapsed time: approx. 3 sec for both parts together
