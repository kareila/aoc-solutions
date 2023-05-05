# Solution to Advent of Code 2022, Day 2
# https://adventofcode.com/2022/day/2

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# converts a plain list of key, val, key, val to a map
list_to_map = fn list ->
  Enum.chunk_every(list, 2) |> Map.new(fn [k, v] -> {k, v} end)
end

# Today's input lines are pairs of uppercase letters.
# Document the input meanings:
# Column 1 - A => 'Rock', B => 'Paper', C => 'Scissors'
# Column 2 - X => 'Rock', Y => 'Paper', Z => 'Scissors'

score_shape = fn line ->
  %{ "X" => 1, "Y" => 2, "Z" => 3 } |> Map.fetch!(String.last(line))
end

score_round = fn line ->
  # 0 for loss, 3 for draw, 6 if win
  # there are only nine possible outcomes, just hash them
  %{ "A X" => 3, # Rock / Rock
     "A Y" => 6, # Rock / Paper
     "A Z" => 0, # Rock / Scissors
     "B X" => 0, # Paper / Rock
     "B Y" => 3, # Paper / Paper
     "B Z" => 6, # Paper / Scissors
     "C X" => 6, # Scissors / Rock
     "C Y" => 0, # Scissors / Paper
     "C Z" => 3, # Scissors / Scissors
  } |> Map.fetch!(line)
end

calc_score = fn line, total ->
  total + score_shape.(line) + score_round.(line)
end

data = read_input.()
total = Enum.reduce(data, 0, calc_score)

IO.puts("Part 1: #{total}")


# New meaning for XYZ!
# Column 1 - A => 'Rock', B => 'Paper', C => 'Scissors'
# Column 2 - X => 'lose', Y => 'draw', Z => 'win'

choose_play = fn line ->
  # convert: map to old meaning for scorer subroutines
  # choice_map: X is one letter lower, Y is same, win is one letter higher
  [convert | choices] = [~w( A X B Y C Z ), ~w( A C B A C B ),
    ~w( A A B B C C ), ~w( A B B C C A )] |> Enum.map(list_to_map)
  choice_map = Enum.zip(~w( X Y Z ), choices) |> Map.new
  [opp, act] = String.split(line)
  choice = Map.fetch!(convert, choice_map[act][opp])
  "#{opp} #{choice}"
end

total = Enum.map(data, choose_play) |> Enum.reduce(0, calc_score)

IO.puts("Part 2: #{total}")
