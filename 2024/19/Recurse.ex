defmodule Recurse do
  @moduledoc """
  Functions that have to be defined in a module in order to recurse.
  """

  @doc "Determine how many ways to construct a given string from the given pieces."
  @spec construct(String.t, [String.t], map) :: {pos_integer | [], map}
  def construct(str, pieces, cache \\ %{})

  def construct(s, _, c) when is_map_key(c, s), do: {c[s], c}

  def construct(str, pieces, cache) do
    {results, cache} = recurse(str, pieces, cache)
    n = Enum.sum(results)
    v = if n == 0, do: [], else: [n]
    {v, Map.put(cache, str, v)}
  end

  defp recurse(str, pieces, cache) do
    find_matches(str, pieces) |>
    Enum.flat_map_reduce(cache, fn substr, cache ->
      if substr == "", do: {[1], cache},
      else: construct(substr, pieces, cache)
    end)
  end

  defp find_matches(str, pieces) do
    Enum.flat_map(pieces, fn p ->
      if String.starts_with?(str, p),
      do: [String.replace_prefix(str, p, "")],
      else: []
    end)
  end
end
