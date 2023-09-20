# Solution to Advent of Code 2021, Day 15
# https://adventofcode.com/2021/day/15

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# parses input as a grid of values
matrix = fn lines ->
  for {line, y} <- Enum.with_index(lines),
      {v, x} <- String.graphemes(line) |> Enum.with_index,
  do: {x, y, String.to_integer(v)}
end

matrix_map = fn matrix ->
  for {x, y, v} <- matrix, into: %{}, do: { {x, y}, v }
end

adj_pos = fn {x, y} ->
  [{x - 1, y}, {x + 1, y}, {x, y - 1}, {x, y + 1}]
end

tile_size = fn data -> trunc(:math.sqrt(map_size(data))) end

# Dijkstra's algorithm
min_path = fn data ->
  max_i = tile_size.(data) - 1
  stop = {max_i, max_i}
  neighbors = fn pos -> adj_pos.(pos) |> then(&Map.take(data, &1)) end
  init = {MapSet.new([{0, 0}]), neighbors.({0, 0}), neighbors.({0, 0})}
  Enum.reduce_while(Stream.cycle([1]), init, fn _, {picked, nb, dist} ->
    # keep picking the next closest point until we reach the end
    pick = Enum.min_by(Map.keys(nb), &Map.fetch!(dist, &1))
    [picked, nb] = [MapSet.put(picked, pick), Map.delete(nb, pick)]
    pn = neighbors.(pick) |> Map.reject(&MapSet.member?(picked, elem(&1,0)))
    dist =
      Enum.reduce(pn, dist, fn {p, v}, dist ->
        d = v + Map.fetch!(dist, pick)
        if Map.has_key?(dist, p) and dist[p] < d do dist[p] else d end |>
        then(&Map.put(dist, p, &1))
      end)
    if stop in Map.keys(pn), do: {:halt, dist[stop]},
    else: {:cont, {picked, Map.merge(nb, pn), dist}}
  end)
end

data = read_input.() |> matrix.() |> matrix_map.()

IO.puts("Part 1: #{min_path.(data)}")


expand_grid = fn data ->
  t_size = tile_size.(data)
  for m <- 0..4, n <- 0..4, i <- 0..(t_size - 1), j <- 0..(t_size - 1),
      y = j + t_size * m, x = i + t_size * n, into: %{},
  do: {{x, y}, Integer.mod(Map.fetch!(data, {i, j}) + m + n - 1, 9) + 1}
end

IO.puts("Part 2: #{expand_grid.(data) |> min_path.()}")

# elapsed time: approx. 11 sec for both parts together
