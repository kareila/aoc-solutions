# Solution to Advent of Code 2017, Day 5
# https://adventofcode.com/2017/day/5

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# My first linked list implementation of this took two seconds to run.
# Part 2 will take over a minute. So switching from list to map...

list_to_map = fn list ->
  Enum.with_index(list) |> Map.new(fn {v, i} -> {i, v} end)
end

data = read_input.() |> Enum.map(&String.to_integer/1) |> list_to_map.()

escape = fn change ->
  Enum.reduce_while(Stream.iterate(0, &(&1 + 1)), {0, data},
  fn t, {i, data} ->
    jump = Map.get(data, i, nil)
    if is_nil(jump), do: {:halt, t},
    else: {:cont, {i + jump, Map.put(data, i, jump + change.(jump))}}
  end)
end

one = fn _ -> 1 end

IO.puts("Part 1: #{escape.(one)}")


strange = fn jump -> if jump > 2, do: -1, else: 1 end

IO.puts("Part 2: #{escape.(strange)}")

# elapsed time: approx. 5.5 sec for both parts together
