# Solution to Advent of Code 2023, Day 7
# https://adventofcode.com/2023/day/7

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# jokers are used in Part 2
parse_line = fn line ->
  [hand, bid] = String.split(line)
  %{hand: String.graphemes(hand), bid: String.to_integer(bid), joker: nil}
end

hand_type = fn hand ->
  case Enum.frequencies(hand) |> Map.values |> Enum.sort do
    [5] -> 7          # five_of_a_kind
    [1,4] -> 6        # four_of_a_kind
    [2,3] -> 5        # full_house
    [1,1,3] -> 4      # three_of_a_kind
    [1,2,2] -> 3      # two_pair
    [1,1,1,2] -> 2    # one_pair
    [1,1,1,1,1] -> 1  # high_card
  end
end

# if our hand contains a joker, use its assignment (Part 2)
substitute_joker = fn h ->
  if is_nil(h.joker), do: h.hand,
  else: Enum.map(h.hand, fn c -> if c == "J", do: h.joker, else: c end)
end

type_strength = fn hand -> hand_type.(substitute_joker.(hand)) end

# weaker cards sorted earlier in the lookup list so
# that stronger cards will have a higher index value
card_strength_jack = fn c ->
  ~w(2 3 4 5 6 7 8 9 T J Q K A)s |> Enum.find_index(&(&1 == c))
end

sort_hands = fn hands, s_fn ->
  Enum.sort_by(hands, &{type_strength.(&1), Enum.map(&1.hand, s_fn)})
end

score_hand = fn {%{bid: bid}, idx} -> bid * idx end

score_all = fn sorted ->
  Enum.with_index(sorted, 1) |> Enum.map(score_hand) |> Enum.sum
end

data = read_input.() |> Enum.map(parse_line)

IO.puts("Part 1: #{sort_hands.(data, card_strength_jack) |> score_all.()}")


card_strength_joker = fn c ->
  ~w(J 2 3 4 5 6 7 8 9 T Q K A)s |> Enum.find_index(&(&1 == c))
end

try_jokers = fn h ->
  other_cards = Enum.reject(h.hand, &(&1 == "J")) |> Enum.uniq
  cond do
    "J" not in h.hand -> h
    Enum.empty?(other_cards) -> %{h | joker: "A"}  # 5 jokers
    true ->
      Enum.map(other_cards, &(%{h | joker: &1})) |>
      sort_hands.(card_strength_joker) |> List.last
  end
end

data = Enum.map(data, try_jokers)

IO.puts("Part 2: #{sort_hands.(data, card_strength_joker) |> score_all.()}")
