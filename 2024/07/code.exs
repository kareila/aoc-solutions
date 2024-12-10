# Solution to Advent of Code 2024, Day 7
# https://adventofcode.com/2024/day/7

Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

data = read_input.() |> Enum.map(&Util.read_numbers/1)


do_op = fn n, [first | rest], op -> [op.(n, first) | rest] end

op_reduce = fn [first | rest], output, op_list ->
  cond do
    Enum.empty?(rest) -> [first]
    first > output -> []  # bail out since numbers can only increase
    true -> Enum.map(op_list, &do_op.(first, rest, &1))
  end
end

calibrate = fn [output | inputs], op_list ->
  Enum.reduce(inputs, [inputs], fn _, lists ->
    Enum.map(lists, &op_reduce.(&1, output, op_list)) |> Enum.concat
  end)
end

filter_true = fn {list, [output | _]} ->
  if output in list, do: output, else: 0
end

check_all = fn ops ->
  for {:ok, v} <- Task.async_stream(data, &calibrate.(&1, ops)) do v
  end |> Enum.zip(data) |> Enum.map(filter_true) |> Enum.sum
end

pt1_ops = [&+/2, &*/2]

IO.puts("Part 1: #{check_all.(pt1_ops)}")

pt2_ops = [fn a, b -> String.to_integer("#{a}#{b}") end | pt1_ops]

IO.puts("Part 2: #{check_all.(pt2_ops)}")
