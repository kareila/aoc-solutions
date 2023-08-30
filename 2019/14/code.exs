# Solution to Advent of Code 2019, Day 14
# https://adventofcode.com/2019/day/14

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_line = fn line ->
  [_, inputs, num, output] = Regex.run(~r/^([^=]+) => (\d+) (\w+)$/, line)
  inputs = String.split(inputs, ", ") |> Enum.map(&String.split/1) |>
    Enum.map(fn [num, item] -> {item, String.to_integer(num)} end)
  %{output => %{yield: String.to_integer(num), need: inputs}}
end

parse_lines = fn lines ->
  Enum.reduce(lines, %{}, fn l, acc -> Map.merge(acc, parse_line.(l)) end)
end

reactions = read_input.() |> parse_lines.()

[goal, base] = ["FUEL", "ORE"]

create = fn amt ->
  init = {[{goal, amt}], %{}}
  Enum.reduce_while(Stream.cycle([1]), init, fn _, {queue, supplies} ->
    if Enum.empty?(queue) do {:halt, supplies[base]}
    else
      [{make, amt} | queue] = queue
      have = Map.get(supplies, make, 0)
      result = fn q, num -> {:cont, {q, Map.put(supplies, make, num)}} end
      cond do
        make == base -> result.(queue, have + amt)
        have >= amt -> result.(queue, have - amt)
        true ->
          [recipe, amt] = [reactions[make], amt - have]
          mult = ceil(amt / recipe.yield)
          Enum.map(recipe.need, fn {item, num} -> {item, num * mult} end)
          |> Enum.concat(queue) |> result.(mult * recipe.yield - amt)
      end
    end
  end)
end

IO.puts("Part 1: #{create.(1)}")


create_until = fn limit ->
  less? = fn n -> create.(n) < limit end
  lo = Stream.iterate(1, &(&1*2)) |> Stream.take_while(less?) |> Enum.at(-1)
  if lo == nil, do: raise(ArgumentError, "limit too low")
  Enum.reduce_while(Stream.cycle([1]), {lo, lo * 2}, fn _, {lo, hi} ->
    mid = div(lo + hi, 2)
    if mid == lo, do: {:halt, lo},
    else: {:cont, if(create.(mid) > limit, do: {lo, mid}, else: {mid, hi})}
  end)
end

IO.puts("Part 2: #{create_until.(1_000_000_000_000)}")
