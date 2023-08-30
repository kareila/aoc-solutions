# Solution to Advent of Code 2019, Day 4
# https://adventofcode.com/2019/day/4

# no input file today
puzzle_input = 372037..905157

zip_digits = fn num ->
  digits = Integer.digits(num)
  Enum.zip(digits, tl(digits))
end

ok_val? = fn num ->
  Enum.reduce_while(zip_digits.(num), false, fn {a,b}, same_bool ->
    cond do
      a == b -> {:cont, true}
      a > b -> {:halt, false}
      true -> {:cont, same_bool}
    end
  end)
end

ok = Enum.filter(puzzle_input, ok_val?)

IO.puts("Part 1: #{Enum.count(ok)}")


strict_double? = fn num ->
  counts =
    Enum.flat_map(zip_digits.(num), fn {a,b} ->
      if a != b, do: [], else: ["#{a}#{a}"] end)
    |> Enum.frequencies |> Map.values
  1 in counts
end

ok = Enum.filter(ok, strict_double?)

IO.puts("Part 2: #{Enum.count(ok)}")
