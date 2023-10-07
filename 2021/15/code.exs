# Solution to Advent of Code 2021, Day 15
# https://adventofcode.com/2021/day/15

Code.require_file("Matrix.ex", "..")
Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

int_vals = fn {p, v} -> {p, String.to_integer(v)} end

tile_size = fn data -> trunc(:math.sqrt(map_size(data))) end

# Dijkstra's algorithm
min_path = fn data ->
  max_i = tile_size.(data) - 1
  stop = {max_i, max_i}
  neighbors = fn pos -> Util.adj_pos(pos) |> then(&Map.take(data, &1)) end
  init = {MapSet.new([{0, 0}]), neighbors.({0, 0}), neighbors.({0, 0})}
  Enum.reduce_while(Stream.cycle([1]), init, fn _, {picked, nb, dist} ->
    # keep picking the next closest point until we reach the end
    pick = Enum.min_by(Map.keys(nb), &Map.fetch!(dist, &1))
    [picked, nb] = [MapSet.put(picked, pick), Map.delete(nb, pick)]
    pn = neighbors.(pick) |> Map.reject(&MapSet.member?(picked, elem(&1,0)))
    dist =
      Enum.reduce(pn, dist, fn {p, v}, dist ->
        d = v + Map.fetch!(dist, pick)
        Map.update(dist, p, d, &Enum.min([&1, d]))
      end)
    if Map.has_key?(pn, stop), do: {:halt, dist[stop]},
    else: {:cont, {picked, Map.merge(nb, pn), dist}}
  end)
end

data = read_input.() |> Matrix.map |> Map.new(int_vals)

IO.puts("Part 1: #{min_path.(data)}")


expand_grid = fn data ->
  t_size = tile_size.(data)
  for m <- 0..4, n <- 0..4, i <- 0..(t_size - 1), j <- 0..(t_size - 1),
      y = j + t_size * m, x = i + t_size * n, into: %{},
  do: {{x, y}, Integer.mod(Map.fetch!(data, {i, j}) + m + n - 1, 9) + 1}
end

IO.puts("Part 2: #{expand_grid.(data) |> min_path.()}")

# elapsed time: approx. 11 sec for both parts together
