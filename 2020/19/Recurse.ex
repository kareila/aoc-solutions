defmodule Recurse do
  @moduledoc """
  Functions that have to be defined in a module in order to recurse.
  """

  @doc "Recursively search for pattern matches."
  @spec match(map, integer, integer) :: [integer]
  def match(data, ri, mi \\ 0) do
    rule = Map.fetch!(data.rules, ri)
    ab = hd(hd(rule))  # first element of first (or only) sub-rule
    cond do
      mi >= length(data.msg) -> []
      ab in ~w(a b)s ->
        if ab == Enum.at(data.msg, mi), do: [mi + 1], else: []
      true -> Enum.flat_map(rule, &check_opt(&1, mi, data))
    end
  end

  defp check_opt(rnums, mi, data) do
    Enum.reduce(rnums, [mi], fn subrule, sub_matches ->
      Enum.flat_map(sub_matches, &match(data, subrule, &1))
    end)
  end
end
