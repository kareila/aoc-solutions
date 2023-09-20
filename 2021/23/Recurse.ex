defmodule Recurse do
  @moduledoc """
  Functions that have to be defined in a module in order to recurse.
  """

  @doc "Recursively minimize total movement cost."
  @spec solve(map, fun, map) :: {integer, map}
  def solve(data, possible_moves, cache \\ %{}) do
    ckey = data.ckey.(data)
    cond do
      is_map_key(cache, ckey) -> {cache[ckey], cache}
      data.done.(data) -> {0, Map.put(cache, ckey, 0)}
      true ->
        best = 999999999999999  # impossible
        {best, cache} =
          Enum.reduce(possible_moves.(data), {best, cache},
          fn {cost, moved}, {best, cache} ->
            {add, cache} = solve(moved, possible_moves, cache)
            {Enum.min([best, cost + add]), cache}
          end)
        {best, Map.put(cache, ckey, best)}
    end
  end
end
