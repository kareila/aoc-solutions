# Solution to Advent of Code 2023, Day 4
# https://adventofcode.com/2023/day/4

Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_line = fn line ->
  [_, data] = String.split(line, ":")
  [winners, draws] = String.split(data, "|")
  %{winners: Util.read_numbers(winners), draws: Util.read_numbers(draws)}
end

count_matches = fn %{winners: winners, draws: draws} ->
  Enum.filter(draws, &(&1 in winners)) |> Enum.count
end

pow_score = fn n -> if n > 0, do: Integer.pow(2, n - 1), else: 0 end

data = read_input.() |> Enum.map(parse_line) |> Enum.map(count_matches)

IO.puts("Part 1: #{Enum.map(data, pow_score) |> Enum.sum}")


card_pile = fn ->
  Enum.with_index(data, 1) |>
  Map.new(fn {n, i} -> {i, %{matches: n, copies: 1}} end)
end

add_to_pile = fn pile, id, n ->
  v = Map.get(pile, id, nil)
  if is_nil(v) do pile
  else
    Map.put(pile, id, %{v | copies: v.copies + n})
  end
end

process_card = fn id, pile ->
  %{matches: matches, copies: copies} = Map.fetch!(pile, id)
  if matches == 0 do pile
  else
    Enum.reduce(1..matches, pile, fn i, pile ->
      add_to_pile.(pile, id + i, copies)
    end)
  end
end

process_all = fn pile ->
  Map.keys(pile) |> Enum.sort |> Enum.reduce(pile, process_card)
end

count_cards = fn pile ->
  Map.values(pile) |> Enum.map(&(&1.copies)) |> Enum.sum
end

IO.puts("Part 2: #{card_pile.() |> process_all.() |> count_cards.()}")
