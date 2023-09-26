# Solution to Advent of Code 2017, Day 2
# https://adventofcode.com/2017/day/2

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

all_matches = fn str, pat ->
  Regex.scan(pat, str, capture: :all_but_first) |> Enum.concat
end

read_numbers = fn str ->
  all_matches.(str, ~r/(\d+)/) |> Enum.map(&String.to_integer/1)
end

data = read_input.() |> Enum.map(read_numbers)

checksum = fn row ->
  {min_n, max_n} = Enum.min_max(row)
  max_n - min_n
end

IO.puts("Part 1: #{Enum.map(data, checksum) |> Enum.sum}")


find_divisible = fn row ->
  s_row = Enum.sort(row, :desc)
  Enum.reduce_while(s_row, tl(s_row), fn num, rest ->
    x = Enum.find(rest, fn x -> rem(num, x) == 0 end)
    if is_nil(x), do: {:cont, tl(rest)}, else: {:halt, div(num, x)}
  end)
end

IO.puts("Part 2: #{Enum.map(data, find_divisible) |> Enum.sum}")
