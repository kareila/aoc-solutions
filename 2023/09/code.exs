# Solution to Advent of Code 2023, Day 9
# https://adventofcode.com/2023/day/9

Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

data = read_input.() |> Enum.map(&Util.read_numbers/1)

next_seq = fn line ->
  Enum.map(Enum.zip(line, tl(line)), fn {a, b} -> b - a end)
end

list_diffs = fn line ->
  Enum.reduce_while(Stream.cycle([1]), [line], fn _, list ->
    seq = next_seq.(hd(list))
    if Enum.all?(seq, &(&1 == 0)), do: {:halt, Enum.map(list, &List.last/1)},
    else: {:cont, [seq | list]}
  end)
end

sum_nxt = fn lines -> Enum.flat_map(lines, list_diffs) |> Enum.sum end

IO.puts("Part 1: #{data |> sum_nxt.()}")
IO.puts("Part 2: #{Enum.map(data, &Enum.reverse/1) |> sum_nxt.()}")
