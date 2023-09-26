# Solution to Advent of Code 2017, Day 15
# https://adventofcode.com/2017/day/15

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_line = fn line ->
  String.split(line) |> List.last |> String.to_integer
end

parse_input = fn input ->
  [val_a, val_b] = Enum.map(input, parse_line)
  %{a: %{factor: 16807, mod: 4, value: val_a},  # mod is for Part 2
    b: %{factor: 48271, mod: 8, value: val_b}}
end

judge = fn a, b ->
  a_val = Bitwise.band(a, 65535)  # (16 ** 4) - 1
  b_val = Bitwise.band(b, 65535)
  if a_val == b_val, do: 1, else: 0
end

# As soon as I saw the phrase "40 million pairs" I went looking
# for mathematical shortcuts and found a suggestion related to
# something called a Mersenne prime, which I used here.
next_val = fn g ->
  mp = 2_147_483_647  # can also be expressed as (2 ** 31) - 1
  prod = g.value * g.factor
  val = Bitwise.band(prod, mp) + Bitwise.bsr(prod, 31)
  if Bitwise.bsr(val, 31) != 0, do: val - mp, else: val
end

data = read_input.() |> parse_input.()

judge_num = fn n ->
  Enum.reduce(1..n, {data, 0}, fn _, {data, tot} ->
    data = %{a: %{data.a | value: next_val.(data.a)},
             b: %{data.b | value: next_val.(data.b)}}
    {data, tot + judge.(data.a.value, data.b.value)}
  end) |> elem(1)
end

IO.puts("Part 1: #{judge_num.(40_000_000)}")


accumulate_vals = fn n, k ->
  Enum.reduce_while(Stream.cycle([1]), {data[k], %{}}, fn _, {d, keep} ->
    data = %{d | value: next_val.(d)}
    keep =
      if Bitwise.band(data.value, data.mod - 1) != 0, do: keep,
      else: Map.put(keep, map_size(keep), data.value)
    if map_size(keep) == n, do: {:halt, keep},
    else: {:cont, {data, keep}}
  end) |> Enum.sort |> Enum.map(&elem(&1,1))
end

# generating the A & B lists in parallel speeds things up a bit
mod_vals = fn n -> [:a, :b] |>
  Enum.map(fn k -> Task.async(fn -> accumulate_vals.(n, k) end) end) |>
  Enum.map(fn t -> Task.await(t, :infinity) end)
end

judge_vals = fn n ->
  [a_list, b_list] = mod_vals.(n)
  Enum.reduce(a_list, {b_list, 0}, fn a, {[b | b_rest], tot} ->
    {b_rest, tot + judge.(a, b)}
  end) |> elem(1)
end

IO.puts("Part 2: #{judge_vals.(5_000_000)}")

# elapsed time: approx. 13 sec for both parts together
