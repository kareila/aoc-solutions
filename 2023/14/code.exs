# Solution to Advent of Code 2023, Day 14
# https://adventofcode.com/2023/day/14

Code.require_file("Matrix.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_lines = fn lines ->
  # dropping the fixed rocks from the data is a slight speed boost
  grid = Matrix.map(lines) |> Map.reject(&(elem(&1,1) == "#"))
  %{grid: grid, edge: Matrix.grid(lines) |> Matrix.min_max_y |> elem(1)}
end

data = read_input.() |> parse_lines.()

list_rocks = fn g -> Map.filter(g, &(elem(&1,1) == "O")) |> Map.keys end

next_pos = fn {x, y}, {i, j} -> {x + i, y + j} end

move_rock = fn pos, dir, grid ->
  Enum.reduce_while(Stream.cycle([1]), {pos, grid}, fn _, {p, grid} ->
    nxt = next_pos.(p, dir)
    if Map.get(grid, nxt) != ".", do: {:halt, Map.put(grid, p, "O")},
    else: {:cont, {nxt, Map.put(grid, p, ".")}}
  end)
end

move_all = fn dir, %{grid: grid} = data ->
  dir_sort =
    %{{0, -1} => [1, :asc], {0, 1} => [1, :desc], {1, 0} => [0, :desc],
      {-1, 0} => [0, :asc]} |> Map.fetch!(dir) |>
    then(fn [a, b] -> fn list -> List.keysort(list, a, b) end end)
  list_rocks.(grid) |> dir_sort.() |>
  Enum.reduce(grid, &move_rock.(&1, dir, &2)) |> then(&(%{data | grid: &1}))
end

calc_load = fn %{grid: grid, edge: edge} ->
  list_rocks.(grid) |> Enum.map(fn {_, y} -> edge - y + 1 end) |> Enum.sum
end

IO.puts("Part 1: #{move_all.({0, -1}, data) |> calc_load.()}")


do_spin = fn data ->
  [{0, -1}, {-1, 0}, {0, 1}, {1, 0}] |> Enum.reduce(data, move_all)
end

find_cycle = fn data ->
  Enum.reduce_while(Stream.iterate(1, &(&1 + 1)), {data, [], nil},
  fn t, {data, history, repeat} ->
    history = [data.grid | history]
    data = do_spin.(data)
    cond do
      data.grid == repeat -> {:halt, {t, length(history), data}}
      is_nil(repeat) and data.grid in history ->
        {:cont, {data, [], data.grid}}
      true -> {:cont, {data, history, repeat}}
    end
  end)
end

use_cycle = fn data ->
  {t, len, data} = find_cycle.(data)
  extra = rem(1_000_000_000 - t, len)
  Enum.reduce(1..extra, data, fn _, data -> do_spin.(data) end)
end

IO.puts("Part 2: #{use_cycle.(data) |> calc_load.()}")

# elapsed time: approx. 2.2 sec for both parts together
