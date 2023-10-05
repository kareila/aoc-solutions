defmodule Recurse do
  @moduledoc """
  Functions that have to be defined in a module in order to recurse.
  """

  @doc "Play a game using some number of cards."
  @spec play_game(map) :: tuple
  def play_game(deck) do
    Enum.reduce_while(Stream.cycle([1]), {deck, MapSet.new},
    fn _, {deck, seen} ->
      if MapSet.member?(seen, deck) do {:halt, {1, deck}}
      else
        seen = MapSet.put(seen, deck)
        deck = play_round(deck)
        if is_map(deck), do: {:cont, {deck, seen}}, else: {:halt, deck}
      end
    end)
  end

  defp play_round(%{1 => d1, 2 => d2} = deck) do
    cond do
      Enum.empty?(d1) -> {2, deck}
      Enum.empty?(d2) -> {1, deck}
      true ->
        [[c1 | d1], [c2 | d2]] = [d1, d2]
        # do we recurse? (the quantity of cards remaining is at least
        # the number shown on the card just drawn, for both players)
        winner =
          if length(d1) >= c1 and length(d2) >= c2 do
            subdeck = %{1 => Enum.take(d1, c1), 2 => Enum.take(d2, c2)}
            play_game(subdeck) |> elem(0)
          else
            if c1 > c2, do: 1, else: 2  # no ties are possible
          end
        case winner do
          1 -> %{1 => d1 ++ [c1, c2], 2 => d2}
          2 -> %{1 => d1, 2 => d2 ++ [c2, c1]}
        end
    end
  end
end
