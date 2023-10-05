# Solution to Advent of Code 2020, Day 11
# https://adventofcode.com/2020/day/11

Code.require_file("Matrix.ex", "..")
Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

init_data = read_input.() |> Matrix.map

pt1_state = %{data: init_data, tolerance: 4,
  sur_pos: fn p, _ -> Util.sur_pos(p) end}

count_occupied = fn data -> Enum.count(data, fn {_, v} -> v == "#" end) end

count_sur_occ = fn pos, %{data: data, sur_pos: sur_pos} = state ->
  sur_pos.(pos, state) |> then(&Map.take(data, &1)) |> count_occupied.()
end

apply_rule = fn %{data: data} = state, t1, t2, occ_fn ->
  select = fn {p, v} -> v == t1 and occ_fn.(count_sur_occ.(p, state)) end
  change = Map.filter(data, select) |> Map.keys |> Map.from_keys(t2)
  {map_size(change), Map.merge(data, change)}
end

apply_empty_rule = fn state ->
  apply_rule.(state, "L", "#", fn occ -> occ == 0 end)
end

apply_occupied_rule = fn %{tolerance: tolerance} = state ->
  apply_rule.(state, "#", "L", fn occ -> occ >= tolerance end)
end

seek_equilibrium = fn init_state ->
  Stream.cycle([apply_empty_rule, apply_occupied_rule]) |>
  Enum.reduce_while(init_state, fn rule, state ->
    {changed, data} = rule.(state)
    if changed != 0, do: {:cont, %{state | data: data}},
    else: {:halt, count_occupied.(data)}
  end)
end

IO.puts("Part 1: #{seek_equilibrium.(pt1_state)}")


first_chair_in_direction = fn pos, {dx, dy}, data ->
  Enum.reduce_while(Stream.cycle([1]), pos, fn _, {x, y} ->
    pos = {x + dx, y + dy}
    cond do
      not is_map_key(data, pos) -> {:halt, nil}
      data[pos] == "." -> {:cont, pos}
      true -> {:halt, pos}
    end
  end)
end

sur_pos = fn pos, %{data: data} ->
  Util.sur_pos({0,0}) |>
  Enum.map(&first_chair_in_direction.(pos, &1, data)) |>
  Enum.reject(&is_nil/1)
end

pt2_state = %{data: init_data, tolerance: 5, sur_pos: sur_pos}

IO.puts("Part 2: #{seek_equilibrium.(pt2_state)}")
