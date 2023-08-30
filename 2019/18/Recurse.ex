defmodule Recurse do
  @moduledoc """
  Functions that have to be defined in a module in order to recurse.
  """

  @doc "Search for minimum steps to find all keys."
  @spec search(list(String.t), non_neg_integer, fun) :: non_neg_integer
  def search(locs, n_find, key_fn) do
    do_search(locs, n_find, [], key_fn, %{}) |> elem(0)
  end
  # Wow, memoizing a nested recursive function in Elixir is annoying.

# do_search(list, non_neg_integer, list, fun, map) :: tuple
  defp do_search(_, 0, _, _, cache), do: {0, cache}

  defp do_search(locs, _, found_keys, _, cache)
    when is_map_key(cache, {locs, found_keys}) do
      {Map.fetch!(cache, {locs, found_keys}), cache}
  end

  defp do_search(locs, n_find, found_keys, key_fn, cache) do
    init = {999_999_999, cache}
    input = loc_keys(locs, found_keys, key_fn)
    if Enum.empty?(input), do:
      raise(ArgumentError, "unsolvable: #{locs} #{found_keys}")
    Enum.reduce(input, init, fn {reachable, loc}, {best, cache} ->
      rest = locs -- [loc]
      {dist, cache} =
        find_best(reachable, rest, n_find, found_keys, key_fn, cache)
      best = Enum.min([best, dist])
      {best, Map.put(cache, {locs, found_keys}, best)}
    end)
  end

  defp loc_keys(locs, found_keys, key_fn) do
    Enum.map(locs, fn loc -> {key_fn.(loc, found_keys), loc} end) |>
    Enum.reject(&Enum.empty?(elem(&1,0)))
  end

  defp find_best(reachable, locs, n_find, found_keys, key_fn, cache) do
    init = {999_999_999, cache}
    Enum.reduce(reachable, init, fn {k, d}, {best, cache} ->
      k_locs = Enum.sort([k | locs])
      k_keys = Enum.sort([k | found_keys])
      {dist, cache} = do_search(k_locs, n_find - 1, k_keys, key_fn, cache)
      {Enum.min([best, dist + d]), cache}
    end)
  end
end
