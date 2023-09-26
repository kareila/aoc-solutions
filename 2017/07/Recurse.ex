defmodule Recurse do
  @moduledoc """
  Functions that have to be defined in a module in order to recurse.
  """

  @doc "Add the weight of a node to the weight of all its children."
  @spec total_weight(String.t, map, map) :: {integer, map}
  def total_weight(name, data, cache \\ %{}) do
    if Map.has_key?(cache, name) do {cache[name], cache}
    else
      n = Map.fetch!(data, name)
      {vals, cache} =
        Enum.map_reduce(n.children, cache, fn c, cache ->
          total_weight(c, data, cache)
        end)
      tot = Enum.sum(vals) + n.weight
      {tot, Map.put(cache, name, tot)}
    end
  end
end
