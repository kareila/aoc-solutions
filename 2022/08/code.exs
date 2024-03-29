# Solution to Advent of Code 2022, Day 8
# https://adventofcode.com/2022/day/8

Code.require_file("Matrix.ex", "..")
Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

cols = fn matrix -> Util.group_tuples(matrix, 0) |> Map.values end
rows = fn matrix -> Util.group_tuples(matrix, 1) |> Map.values end

# For part 1, the question is how many trees on the grid
# can be seen from the outside - that means we need to track
# which trees we saw, not just how many along each line.
# Initial height is -1 so that we can see a tree of height 0.

seen_from_edge = fn list ->
  Enum.reduce(list, {-1, []}, fn {x, y, v}, {h, seen} ->
    if v > h, do: {v, [{x, y} | seen]}, else: {h, seen}
  end) |> elem(1)
end
    
check_edge = fn data, reverse? ->
  if reverse? do Enum.map(data, &Enum.reverse/1) else data end
  |> Enum.map(seen_from_edge)
end

num_seen = fn data ->
  cols_rows = [cols.(data), rows.(data)]
  [north, west] = Enum.map(cols_rows, &check_edge.(&1, false))
  [south, east] = Enum.map(cols_rows, &check_edge.(&1, true))
  List.flatten([north, south, west, east]) |> Enum.uniq |> length
end

data = read_input.() |> Matrix.grid

IO.puts("Part 1: #{num_seen.(data)}")


# For part 2, the question is how many trees can we see
# from the top of each tree. Ignore all the outer ones,
# since they will always have zero trees on one side.

count_tree_dir = fn tv, range, h_fn ->
  Enum.reduce_while(range, 0, fn i, sum ->
    if h_fn.(i) >= tv, do: {:halt, sum + 1}, else: {:cont, sum + 1}
  end)
end

count_tree_col = fn {tx, _, tv}, data, range ->
  count_tree_dir.(tv, range, fn i -> Map.get(data, {tx, i}) end)
end

count_tree_row = fn {_, ty, tv}, data, range ->
  count_tree_dir.(tv, range, fn i -> Map.get(data, {i, ty}) end)
end

score_tree = fn tree, data, lim ->
  [count_tree_col.(tree, data, elem(tree,1) - 1 .. 0//-1),  # up
   count_tree_col.(tree, data, elem(tree,1) + 1 .. lim.y),  # down
   count_tree_row.(tree, data, elem(tree,0) - 1 .. 0//-1),  # left
   count_tree_row.(tree, data, elem(tree,0) + 1 .. lim.x)]  # right
  |> Enum.product
end

all_scores = fn matrix ->
  data = Matrix.map(matrix)
  {_, x_max, _, y_max} = Matrix.limits(matrix)
  limit = %{x: x_max, y: y_max}
  for tree <- matrix, {x, y, _} = tree,
    x not in [0, limit.x] and y not in [0, limit.y]
    do score_tree.(tree, data, limit)
  end
end

scores = all_scores.(data)

IO.puts("Part 2: #{Enum.max(scores)}")
