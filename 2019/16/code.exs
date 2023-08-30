# Solution to Advent of Code 2019, Day 16
# https://adventofcode.com/2019/day/16

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_input = fn line ->  # can't use Int.digits in case the 1st digit is 0
  String.graphemes(line) |> Enum.map(&String.to_integer/1)
end

data = read_input.() |> hd |> parse_input.()

pattern = fn pos ->
  Stream.cycle([0, 1, 0, -1]) |>
  Stream.flat_map(&Stream.duplicate(&1, pos)) |> Stream.drop(1)
end

calc_pat = fn len ->  # input length never changes
  Enum.map(1..len, pattern) |> Enum.map(&Enum.take(&1, len))
end

calc_digit = fn input, mult ->
  Enum.zip_with(input, mult, &*/2) |> Enum.sum |> abs |> Integer.mod(10)
end

fft = fn num, input ->
  pat = length(input) |> calc_pat.()
  Enum.reduce(1..num, input, fn _, input ->
    Enum.map(pat, fn mult -> calc_digit.(input, mult) end)
  end) |> Enum.take(8) |> Integer.undigits
end

IO.puts("Part 1: #{fft.(100, data)}")


# This is fine for small numbers, but for larger numbers
# with known offsets, we need to seek optimizations.
# The nature of our pattern is such that if the offset is
# larger than the midpoint of the input, we can do a backwards
# running sum (00001, 00011, 00111, etc.)

quick_rev = fn num, input ->
  newlen = length(input) * 10_000
  input = Stream.cycle(input) |> Stream.take(newlen) |> Enum.to_list
  offset = Enum.take(input, 7) |> Integer.undigits
  if offset < div(length(input), 2), do: raise(ArgumentError)
  input = Enum.drop(input, offset) |> Enum.reverse
  Enum.reduce(1..num, input, fn _, input ->
    Enum.map_reduce(input, 0, fn n, tot ->
      tot = tot + n
      {Integer.mod(tot, 10), tot}
    end) |> elem(0)
  end) |> Enum.reverse |> Enum.take(8) |> Integer.undigits
end

IO.puts("Part 2: #{quick_rev.(100, data)}")

# elapsed time: approx. 2.5 sec for both parts together
