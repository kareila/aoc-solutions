defmodule Recurse do
  @moduledoc """
  Functions that have to be defined in a module in order to recurse.
  """

  @doc "Create the strongest bridge possible from the remaining components."
  @spec strongest(integer, [list], [list]) :: {integer, [list]}
  def strongest(port \\ 0, current \\ [], rest) do
    possible = Enum.filter(rest, fn p -> port in p end)
    if Enum.empty?(possible) do  # no further extensions possible
      {strength(current), current}
    else
      scores =
        Enum.map(possible, fn [a, b] ->
          nxt = if port == a, do: b, else: a
          strongest(nxt, [[a, b] | current], rest -- [[a, b]])
        end)
      List.keysort(scores, 0) |> List.last  # choose the highest score
    end
  end

  @doc "Create the longest bridge possible from the remaining components."
  @spec longest(integer, [list], [list]) :: {integer, [list]}
  def longest(port \\ 0, current \\ [], rest) do
    possible = Enum.filter(rest, fn p -> port in p end)
    if Enum.empty?(possible) do  # no further extensions possible
      {length(current), current}
    else
      scores =
        Enum.map(possible, fn [a, b] ->
          nxt = if port == a, do: b, else: a
          longest(nxt, [[a, b] | current], rest -- [[a, b]])
        end)
      maxlen = List.keysort(scores, 0) |> List.last |> elem(0)
      best = Enum.group_by(scores, &elem(&1,0), &elem(&1,1)) |>
             Map.fetch!(maxlen) |> Enum.max_by(&strength/1)
      {maxlen, best}
    end
  end

  @doc "Rate the strength of a bridge."
  @spec strength([list]) :: integer
  def strength(bridge), do: Enum.map(bridge, &Enum.sum/1) |> Enum.sum
end
