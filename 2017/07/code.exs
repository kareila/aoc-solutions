# Solution to Advent of Code 2017, Day 7
# https://adventofcode.com/2017/day/7

require Recurse  # for total_weight()

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_line = fn line ->
  data = String.split(line, " -> ")
  child_str = if length(data) == 1, do: "", else: Enum.at(data, 1)
  [_, name, num_str] = Regex.run(~r/^(\S+) .(\d+)/, hd(data))
  %{name: name, weight: String.to_integer(num_str),
    children: String.split(child_str, ", ", trim: true)}
end

parse_input = fn lines ->
  Enum.map(lines, parse_line) |>
  Enum.reduce(%{}, fn info, nodes -> Map.put(nodes, info.name, info) end)
end

find_root = fn nodes ->
  leaves = Map.values(nodes) |> Enum.flat_map(fn n -> n.children end)
  MapSet.new(Map.keys(nodes)) |> MapSet.difference(MapSet.new(leaves)) |>
  MapSet.to_list |> hd
end

data = read_input.() |> parse_input.()

IO.puts("Part 1: #{find_root.(data)}")


# Add each node's parent to the saved info.
add_parents = fn nodes ->
  Enum.reduce(nodes, nodes, fn {name, info}, nodes ->
    Enum.reduce(info.children, nodes, fn c, nodes ->
      Map.put(nodes, c, Map.put(nodes[c], :parent, name))
    end)
  end)
end

# Find the total weight of each node and add it to the map.
all_weights = fn nodes ->
  Enum.reduce(nodes, %{}, fn {name, _}, weights ->
    Recurse.total_weight(name, nodes, weights) |> elem(1)
  end) |> Map.new(fn {k, v} -> {k, %{tot: v}} end) |>
  Map.merge(add_parents.(nodes), fn _, v1, v2 -> Map.merge(v1, v2) end)
end

child_weights = fn name, nodes ->
  n = Map.fetch!(nodes, name)
  Enum.group_by(n.children, fn c -> nodes[c].tot end)
end

# Problems is plural for the (non-example) case where the node that
# needs to be corrected is not directly on top of the lowest node.
find_problems = fn nodes ->
  Map.keys(nodes) |> Enum.map(&child_weights.(&1, nodes)) |>
  # for the unbalanced groups, find the one child with a different weight
  Enum.flat_map(&Map.to_list/1) |>
  Enum.flat_map(fn {_, v} -> if length(v) == 1, do: v, else: [] end)
end

# Opposite of find_root: find the highest given node, not the lowest.
find_tip = fn nodes ->
  Enum.reduce_while(Stream.cycle([1]), nodes, fn _, nodes ->
    if map_size(nodes) == 1, do: {:halt, Map.keys(nodes) |> hd},
    else: {:cont, Map.delete(nodes, find_root.(nodes))}
  end)
end

find_unbalanced = fn nodes ->
  nodes = all_weights.(nodes)
  wrong_name = Map.take(nodes, find_problems.(nodes)) |> find_tip.()
  [wrong, right] = child_weights.(nodes[wrong_name].parent, nodes) |>
    Enum.group_by(&length(elem(&1,1)), &elem(&1,0)) |>
    Map.split([1]) |> Tuple.to_list |> Enum.map(&hd(hd(Map.values(&1))))
  nodes[wrong_name].weight - wrong + right
end

IO.puts("Part 2: #{find_unbalanced.(data)}")
