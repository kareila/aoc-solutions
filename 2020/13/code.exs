# Solution to Advent of Code 2020, Day 13
# https://adventofcode.com/2020/day/13

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_integers = fn v ->
  n = Integer.parse(v, 10)
  if n == :error, do: v, else: elem(n, 0)
end

parse_input = fn [time_now, ids] ->
  bus = String.split(ids, ",") |> Enum.map(parse_integers) |>
        Enum.with_index |> Enum.reject(&elem(&1,0) == "x")
  %{time: String.to_integer(time_now), bus: bus}
end

data = read_input.() |> parse_input.()

find_soonest = fn ->
  Enum.map(data.bus, fn {b, _} ->
    Enum.reduce_while(Stream.cycle([b]), 0, fn b, bus ->
      if bus >= data.time, do: {:halt, {bus, b}}, else: {:cont, bus + b}
    end)
  end) |> Enum.min |> then(fn {t, b} -> b * (t - data.time) end)
end

IO.puts("Part 1: #{find_soonest.()}")


# return a list of bus IDs that are in the correct position at time t
# (at t = 0, the first bus listed will be the only one in the right place)
find_overlaps = fn t ->
  Enum.flat_map(data.bus, fn {b, i} ->
    if rem(t + i, b) == 0, do: [b], else: []
  end)
end

find_period = fn ->
  [skip] = find_overlaps.(0)
  Enum.reduce_while(Stream.cycle([1]), {skip, 1, %{}, skip},
  fn _, {skip, num, skip_sizes, t} ->
    found = Enum.sort(find_overlaps.(t))
    {n, k} = {length(found), Enum.join(found, ",")}
    cond do
      n == length(data.bus) -> {:halt, t}
      n > num and Map.has_key?(skip_sizes, k) ->
        new_skip = t - skip_sizes[k]
        {:cont, {new_skip, n, skip_sizes, t + new_skip}}
      true ->
        {:cont, {skip, num, Map.put(skip_sizes, k, t), t + skip}}
    end
  end)
end

IO.puts("Part 2: #{find_period.()}")
