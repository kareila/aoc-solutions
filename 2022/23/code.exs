# Solution to Advent of Code 2022, Day 23
# https://adventofcode.com/2022/day/23

Code.require_file("Matrix.ex", "..")
Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# this returns a MapSet (might be empty)
get_adjacent_dirs_occupied = fn pos, data ->
  Enum.map(Util.sur_pos(pos), &Map.get(data.grid, &1, ".")) |>
  Enum.zip(~w(NW W SW N NE E SE S)s) |> Enum.flat_map(fn {v, dir} ->
  if v != "#", do: [], else: [dir] end) |> MapSet.new
end

make_rule = fn dirs, {dx, dy} ->
  fn {x, y}, adj ->
    if MapSet.disjoint?(adj, dirs), do: {x + dx, y + dy}, else: nil
  end
end

init_rules = [
  MapSet.new(~w(NW NE N)s) |> make_rule.({ 0, -1}),  # north rule
  MapSet.new(~w(SW SE S)s) |> make_rule.({ 0,  1}),  # south rule
  MapSet.new(~w(NW SW W)s) |> make_rule.({-1,  0}),  # west rule
  MapSet.new(~w(NE SE E)s) |> make_rule.({ 1,  0}),  # east rule
]

list_elves = fn grid -> Util.group_tuples(grid, 1, 0) |> Map.fetch!("#") end

try_move = fn pos, {choices, collisions}, adj, data ->
  Enum.reduce_while(data.rules, {choices, collisions},
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
  Enum.reduce(list_elves.(data.grid), {%{}, MapSet.new},
  fn elf, {choices, collisions} ->
    adj = get_adjacent_dirs_occupied.(elf, data)
    if Enum.empty?(adj), do: {choices, collisions},
    else: try_move.(elf, {choices, collisions}, adj, data)
  end) |> elem(0)
end

# returns a tuple of updated data and the number of moves made
apply_choices = fn data ->
  {new, old} = propose_moves.(data) |> Enum.unzip
  grid = Map.drop(data.grid, old) |> Map.merge(Map.from_keys(new, "#"))
  rules = Enum.slide(data.rules, 0, -1)
  {%{data | rules: rules, grid: grid}, length(new)}
end

num_empty_tiles = fn data ->
  Matrix.print_sparse_map(data.grid) |> String.replace("\n", "") |>
  String.graphemes |> Enum.count(&(&1 != "#"))
end

init_data = fn lines -> %{grid: Matrix.map(lines), rules: init_rules} end

data = Enum.reduce(1..10, read_input.() |> init_data.(), fn _, data ->
  apply_choices.(data) |> elem(0)
end)

IO.puts("Part 1: #{num_empty_tiles.(data)}")


# pick up where we left off
rounds =
  Enum.reduce_while(Stream.iterate(11, &(&1 + 1)), data,
    fn n, data ->
      {data, moves} = apply_choices.(data)
      if moves == 0 do {:halt, n}
      else
        if rem(n, 200) == 0, do: IO.puts "Round #{n}..."
        {:cont, data}
      end
    end)

IO.puts("Part 2: #{rounds}")

# elapsed time: approx. 3.3 seconds for both parts together
