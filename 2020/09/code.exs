# Solution to Advent of Code 2020, Day 9
# https://adventofcode.com/2020/day/9

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

data = read_input.() |> Enum.map(&String.to_integer/1)

# reused from Day 1
find_two = fn target, init_data ->
  Enum.reduce_while(init_data, init_data, fn x, init_data ->
    [y, data] = [target - x, List.delete(init_data, x)]
    if y in data, do: {:halt, nil}, else: {:cont, data}
  end)
end

find_invalid = fn len ->
  {preamble, data} = Enum.split(data, len)
  Enum.reduce_while(data, preamble, fn n, nums ->
    has_sum = find_two.(n, nums)
    if is_nil(has_sum), do: {:cont, tl(nums) ++ [n]}, else: {:halt, n}
  end)
end

invalid_num = find_invalid.(25)

IO.puts("Part 1: #{invalid_num}")


find_set = fn list ->
  Enum.reduce_while(Stream.iterate(2, &(&1 + 1)), nil, fn n, _ ->
    first = Enum.take(list, n)
    case Enum.sum(first) do
      s when s > invalid_num -> {:halt, nil}
      s when s < invalid_num -> {:cont, nil}
      _ -> {:halt, Enum.min_max(first) |> Tuple.sum}
    end
  end)
end

result =
  Enum.reduce_while(Stream.cycle([1]), data, fn _, data ->
    result = find_set.(data)
    if is_nil(result), do: {:cont, tl(data)}, else: {:halt, result}
  end)

IO.puts("Part 2: #{result}")
