# Solution to Advent of Code 2022, Day 23
# https://adventofcode.com/2022/day/23

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

min_max_x = fn matrix -> Enum.map(matrix, &elem(&1,0)) |> Enum.min_max end
min_max_y = fn matrix -> Enum.map(matrix, &elem(&1,1)) |> Enum.min_max end

grid_to_string = fn data ->
  pts = Map.keys(data.grid)
  [{min_x, max_x}, {min_y, max_y}] = [min_max_x.(pts), min_max_y.(pts)]
  # convert the data to a list of row strings
  Enum.map(min_y..max_y, fn j ->
    Enum.map_join(min_x..max_x, fn i -> Map.get(data.grid, {i,j}, ".") end)
  end)
end

# this returns a MapSet (might be empty)
get_adjacent_dirs_occupied = fn {x,y}, data ->
  [{x-1, y-1}, {x+1, y-1}, {x-1, y+1}, {x+1, y+1},
   {x, y - 1}, {x, y + 1}, {x - 1, y}, {x + 1, y}] |>
  Enum.zip(~w(NW NE SW SE N S W E)s) |>
  Enum.reduce(MapSet.new, fn {xy, dir}, adj ->
    if Map.get(data.grid, xy, ".") != "#", do: adj,
    else: MapSet.put(adj, dir)
  end)
end

# this returns a list of four rule functions
list_rules = fn data ->
  rules = [
    # north rule
    fn {x,y}, adj ->
      dirs = MapSet.new(~w(NW NE N)s)
      if MapSet.disjoint?(adj, dirs), do: {x, y - 1}, else: nil
    end,
    # south rule
    fn {x,y}, adj ->
      dirs = MapSet.new(~w(SW SE S)s)
      if MapSet.disjoint?(adj, dirs), do: {x, y + 1}, else: nil
    end,
    # west rule
    fn {x,y}, adj ->
      dirs = MapSet.new(~w(NW SW W)s)
      if MapSet.disjoint?(adj, dirs), do: {x - 1, y}, else: nil
    end,
    # east rule
    fn {x,y}, adj ->
      dirs = MapSet.new(~w(NE SE E)s)
      if MapSet.disjoint?(adj, dirs), do: {x + 1, y}, else: nil
    end
  ]
  Enum.concat(rules, rules) |> Enum.slice(data.rule_index, length(rules))
end

list_elves = fn grid ->
  Map.filter(grid, fn {_, v} -> v == "#" end) |> Map.keys
end

try_move = fn pos, {choices, collisions}, adj, data ->
  Enum.reduce_while(list_rules.(data), {choices, collisions},
  fn rule, {choices, collisions} ->
    opt = rule.(pos, adj)
    if opt == nil do {:cont, {choices, collisions}}
    else  # we are committed to this choice, must halt
      cond do
        MapSet.member?(collisions, opt) -> {:halt, {choices, collisions}}
        Map.has_key?(choices, opt) ->
          {:halt, {Map.delete(choices, opt), MapSet.put(collisions, opt)}}
        true -> {:halt, {Map.put(choices, opt, pos), collisions}}
      end
    end
  end)
end

# returns map: key is chosen move, value is current position
propose_moves = fn data ->
  {choices, _} =
    Enum.reduce(list_elves.(data.grid), {%{}, MapSet.new},
    fn elf, {choices, collisions} ->
      adj = get_adjacent_dirs_occupied.(elf, data)
      if Enum.empty?(adj), do: {choices, collisions},
      else: try_move.(elf, {choices, collisions}, adj, data)
    end)
  choices
end

# returns a tuple of updated data and the number of moves made
apply_choices = fn data ->
  choices = propose_moves.(data)
  grid = Enum.reduce(choices, data.grid, fn {new, old}, grid ->
    Map.delete(grid, old) |> Map.put(new, "#")
  end)
  # advance rule_index for the next round of propose_moves
  rule_index = Integer.mod(data.rule_index + 1, list_rules.(data) |> length)
  {%{data | rule_index: rule_index, grid: grid}, choices |> map_size}
end

num_empty_tiles = fn data ->
  grid_to_string.(data) |> Enum.join
  |> String.graphemes |> Enum.count(&(&1 != "#"))
end

init_data = fn lines ->
  %{grid: matrix.(lines) |> matrix_map.(), rule_index: 0}
end

data = Enum.reduce(1..10, read_input.() |> init_data.(), fn _n, data ->
  {data, _moves} = apply_choices.(data)
  data
end)

IO.puts("Part 1: #{num_empty_tiles.(data)}")


# pick up where we left off
rounds =
  Enum.reduce_while(Stream.iterate(11, &(&1 + 1)), data,
    fn n, data ->
      {data, moves} = apply_choices.(data)
      if moves == 0 do {:halt, n}
      else
        if Integer.mod(n, 100) == 0, do: IO.puts "Round #{n}..."
        {:cont, data}
      end
    end)

IO.puts("Part 2: #{rounds}")

# elapsed time: approx. 4 seconds for both parts together
