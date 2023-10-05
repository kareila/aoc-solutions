# Solution to Advent of Code 2020, Day 22
# https://adventofcode.com/2020/day/22

Code.require_file("Util.ex", "..")
Code.require_file("Recurse.ex", ".")

# returns a list of non-blank BLOCKS from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n\n", trim: true)
end

parse_block = fn block ->
  [label | lines] = String.split(block, "\n", trim: true)
  [label] = Util.read_numbers(label)
  {label, Enum.map(lines, &String.to_integer/1)}
end

init_deck = read_input.() |> Map.new(parse_block)

# this is modified in Part 2 to allow recursion
play_round = fn %{1 => d1, 2 => d2} = deck ->
  cond do
    Enum.empty?(d1) -> {2, deck}
    Enum.empty?(d2) -> {1, deck}
    true ->
      [[c1 | d1], [c2 | d2]] = [d1, d2]
      winner = if c1 > c2, do: 1, else: 2  # no ties are possible
      case winner do
        1 -> %{1 => d1 ++ [c1, c2], 2 => d2}
        2 -> %{1 => d1, 2 => d2 ++ [c2, c1]}
      end
  end
end

# this is modified in Part 2 to avoid infinite loops
game_result =
  Enum.reduce_while(Stream.cycle([1]), init_deck, fn _, deck ->
    deck = play_round.(deck)
    if is_map(deck), do: {:cont, deck}, else: {:halt, deck}
  end)

score = fn {victor, deck} ->
  deck[victor] |> Enum.reverse |> Enum.with_index(1) |>
  Enum.map(&Tuple.product/1) |> Enum.sum
end

IO.puts("Part 1: #{score.(game_result)}")


game_result = Recurse.play_game(init_deck)

IO.puts("Part 2: #{score.(game_result)}")
