# Solution to Advent of Code 2023, Day 25
# https://adventofcode.com/2023/day/25

Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_data = fn lines ->
  Enum.reduce(lines, [], fn line, data ->
    [a, bs] = String.split(line, ": ")
    Enum.reduce(String.split(bs), data, fn b, data ->
      [a, b] = Enum.map([a, b], &String.to_atom/1)  # huge speed boost
      [{a, b}, {b, a}] ++ data
    end)
  end) |> Util.group_tuples(0, 1) 
end

data = read_input.() |> parse_data.()

list_connected = fn nodes -> Enum.flat_map(nodes, &Map.fetch!(data, &1)) end

count_edges = fn nodes ->
  Enum.count(list_connected.(nodes), &(not MapSet.member?(nodes, &1)))
end

# https://en.wikipedia.org/wiki/Stoer%E2%80%93Wagner_algorithm
expand_group = fn nodes ->
  in_nodes? = fn n -> MapSet.member?(nodes, n) end
  freq_sort = fn {_, v} -> Enum.count(v, in_nodes?) end
  nxt = Enum.reject(list_connected.(nodes), in_nodes?) |>
        then(&Map.take(data, &1)) |> Enum.sort_by(freq_sort, :desc) |>
        Enum.map(&elem(&1,0))
  prev = count_edges.(nodes)
  t_nodes =
    Enum.reduce_while(nxt, nil, fn n, _ ->
      t_nxt = MapSet.put(nodes, n)
      if count_edges.(t_nxt) > prev, do: {:cont, nil}, else: {:halt, t_nxt}
    end)
  cond do  # not sure this is foolproof but it works for my input
    prev == 3 -> MapSet.size(nodes)
    is_nil(t_nodes) -> MapSet.put(nodes, hd(nxt))
    true -> t_nodes
  end
end

find_cut = fn ->
  [{init, _}] = Enum.take(data, 1)
  Enum.reduce_while(data, MapSet.new([init]), fn _, nodes ->
    nodes = expand_group.(nodes)
    if not is_integer(nodes), do: {:cont, nodes},
    else: {:halt, nodes * (map_size(data) - nodes)}
  end)
end

IO.puts("Part 1: #{find_cut.()}")

# elapsed time: approx. 1.3 sec

# There is no Part 2!  Merry Christmas!
