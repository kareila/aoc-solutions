# Solution to Advent of Code 2020, Day 15
# https://adventofcode.com/2020/day/15

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

data = read_input.() |> hd |> String.split(",") |>
       Enum.map(&String.to_integer/1) |> Enum.with_index(1)

play_to = fn n ->
  [game, {prev, t}] = [Map.new(data), List.last(data)]
  Enum.reduce((t + 1)..(n - 1), {prev, game}, fn t, {prev, game} ->
    speak = if Map.has_key?(game, prev), do: t - game[prev], else: 0
    if rem(t, 6000000) == 0, do: IO.puts("Part 2: ... #{div(t * 100, n)}%")
    {speak, Map.put(game, prev, t)}
  end) |> elem(0)
end

IO.puts("Part 1: #{play_to.(2020)}")
IO.puts("Part 2: #{play_to.(30_000_000)}")

# elapsed time: approx. 13 sec for both parts together
