# Solution to Advent of Code 2018, Day 14
# https://adventofcode.com/2018/day/14

# no input file today
base_num = 503761
limit = base_num + 9

# using a list for recipes is performance-prohibitive
init = %{recipes: %{0 => 3, 1 => 7}, current: [0, 1], new: %{}}

combine = fn data ->
  new = Enum.map(data.current, &Map.fetch!(data.recipes, &1)) |> Enum.sum |>
        Integer.digits |> Enum.with_index(map_size(data.recipes)) |>
        Map.new(fn {v, i} -> {i, v} end)
  %{data | recipes: Map.merge(data.recipes, new), new: new}
end

step = fn data ->
  data = combine.(data)
  new = Enum.map(data.current, fn elf ->
          rem(elf + 1 + data.recipes[elf], map_size(data.recipes))
        end)
  %{data | current: new}
end

improve = fn data ->
  Enum.reduce_while(Stream.cycle([1]), data, fn _, data ->
    data = step.(data)
    if Map.has_key?(data.recipes, limit),
    do: {:halt, data}, else: {:cont, data}
  end)
end

data = improve.(init)

print_scores = fn ->
  Enum.map_join(base_num..limit, &Map.fetch!(data.recipes, &1))
end

IO.puts("Part 1: #{print_scores.()}")


test_str = base_num |> to_string

seek = fn ->
  t_i = String.length(test_str) - 1
  i_num = fn i, d -> Enum.map_join((i - t_i) .. i, &(d.recipes[&1])) end
  Enum.reduce_while(Stream.cycle([1]), data, fn _, data ->
    new_data = step.(data)
    # skipping check_new early on saves us about 20 seconds (YMMV)
    if map_size(data.recipes) < 20_000_000 do {:cont, new_data}
    else
      check_new = new_data.new |> Map.keys |> Enum.sort |>
                  Enum.map(&i_num.(&1, new_data)) |>
                  Enum.find_index(&(&1 == test_str))
      if check_new == nil, do: {:cont, new_data},
      else: {:halt, check_new + map_size(data.recipes) - t_i}
    end
  end)
end

IO.puts("Part 2: #{seek.()}")

# elapsed time: approx. 35 sec for both parts together
