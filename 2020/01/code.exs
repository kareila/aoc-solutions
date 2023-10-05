# Solution to Advent of Code 2020, Day 1
# https://adventofcode.com/2020/day/1

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

data = read_input.() |> Enum.map(&String.to_integer/1)

find_two = fn target, init_data ->
  Enum.reduce_while(init_data, init_data, fn x, init_data ->
    [y, data] = [target - x, List.delete(init_data, x)]
    if y in data, do: {:halt, x * y}, else: {:cont, data}
  end)
end

IO.puts("Part 1: #{find_two.(2020, data)}")


find_three = fn target, init_data ->
  Enum.reduce_while(init_data, init_data, fn x, init_data ->
    data = List.delete(init_data, x)
    y = find_two.(target - x, data)
    if is_integer(y), do: {:halt, x * y}, else: {:cont, data}
  end)
end

IO.puts("Part 2: #{find_three.(2020, data)}")
