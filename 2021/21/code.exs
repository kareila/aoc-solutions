# Solution to Advent of Code 2021, Day 21
# https://adventofcode.com/2021/day/21

Code.require_file("Util.ex", "..")
Code.require_file("Recurse.ex", ".")  # for parallel_games()

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_line = fn line -> Util.read_numbers(line) |> List.to_tuple end

init_die = %{total: 0, value: 0, roll: fn die ->
  %{die | total: die.total + 1, value: Integer.mod(die.value, 100) + 1} end}

format_game = fn pawns, win ->
  %{pawns: pawns, score: %{1 => 0, 2 => 0}, die: init_die,
    winner: nil, winning_score: win}
end

next_stop = fn start, spaces -> Integer.mod(start + spaces - 1, 10) + 1 end

track = fn pnum, spaces, game ->
  stop = next_stop.(game.pawns[pnum], spaces)
  pawns = Map.put(game.pawns, pnum, stop)
  score = Map.update!(game.score, pnum, &(&1 + stop))
  winner = if score[pnum] >= game.winning_score, do: pnum, else: nil
  %{game | pawns: pawns, score: score, winner: winner}
end

take_turn = fn pnum, game ->
  {rolls, die} =
    Enum.map_reduce(1..3, game.die, fn _, die ->
      die = die.roll.(die)
      {die.value, die}
    end)
  track.(pnum, Enum.sum(rolls), %{game | die: die})
end

play_game = fn game ->
  Enum.reduce_while(Stream.cycle([1, 2]), game, fn current_player, game ->
    game = take_turn.(current_player, game)
    if is_nil(game.winner), do: {:cont, game}, else: {:halt, game}
  end)
end

data = read_input.() |> Map.new(parse_line)

calc_one = fn ->
  game = format_game.(data, 1000) |> play_game.()
  loser = Map.fetch!(%{2 => 1, 1 => 2}, game.winner)
  Map.fetch!(game.score, loser) * game.die.total
end

IO.puts("Part 1: #{calc_one.()}")


# Now we need to consider parallel universes, each with their
# own version of the game state, and count the number of wins.
num_wins = format_game.(data, 21) |>
           Recurse.parallel_games(next_stop) |> elem(0)

IO.puts("Part 2: #{Enum.max(num_wins)}")
