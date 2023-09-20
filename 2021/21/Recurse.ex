defmodule Recurse do
  @moduledoc """
  Functions that have to be defined in a module in order to recurse.
  """

  @quantum_rolls [ [3,1], [9,1], [4,3], [8,3], [5,6], [7,6], [6,7] ]

  @doc "Recursively play a game with all possible outcomes."
  @spec parallel_games(map, fun, map) :: {[integer], map}
  def parallel_games(game, next_stop, cache \\ %{}) do
    %{pawns: %{1 => pawn1,  2 => pawn2}} = game
    %{score: %{1 => score1, 2 => score2}} = game
    ckey = "#{pawn1},#{score1},#{pawn2},#{score2}"
    cond do
      is_map_key(cache, ckey) -> {cache[ckey], cache}
      score2 >= game.winning_score -> {[0, 1], cache}
      true ->
        {wins, cache} =
          Enum.reduce(@quantum_rolls, {[0, 0], cache},
          fn [roll, freq], {[wins1, wins2], cache} ->
            new_pos = next_stop.(pawn1, roll)
            # players swap places
            game = %{game | pawns: %{1 => pawn2,  2 => new_pos},
                            score: %{1 => score2, 2 => score1 + new_pos}}
            {[w2, w1], cache} = parallel_games(game, next_stop, cache)
            {[wins1 + (w1 * freq), wins2 + (w2 * freq)], cache}
          end)
        {wins, Map.put(cache, ckey, wins)}
    end
  end
end
