# Solution to Advent of Code 2023, Day 13
# https://adventofcode.com/2023/day/13

Code.require_file("Matrix.ex", "..")

# returns a list of non-blank BLOCKS from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n\n", trim: true)
end

parse_block = fn b ->
  rows = String.split(b, "\n", trim: true) |> Enum.map(&String.graphemes/1)
  %{rows: rows, cols: Matrix.transpose(rows)}
end

data = read_input.() |> Enum.map(parse_block)

compare_lines = fn {l1, l2} ->
  Enum.zip_with([l1, l2], fn [a, b] -> if a == b, do: 0, else: 1 end)
end

find_reflection = fn lines, errors ->
  Enum.reduce_while(1..(length(lines) - 1), 0, fn i, _ ->
    {left, right} = Enum.split(lines, i)
    pairs = Enum.reverse(left) |> Enum.zip(right)
    changed = Enum.flat_map(pairs, compare_lines) |> Enum.sum
    if changed == errors, do: {:halt, i}, else: {:cont, 0}
  end)
end

find_both = fn g, e ->
  v = find_reflection.(g.rows, e) * 100 + find_reflection.(g.cols, e)
  if v != 0, do: v, else: raise(RuntimeError, "no solution found")
end

# the smudged reflection has only one differing pixel
IO.puts("Part 1: #{Enum.map(data, &find_both.(&1, 0)) |> Enum.sum}")
IO.puts("Part 2: #{Enum.map(data, &find_both.(&1, 1)) |> Enum.sum}")
