defmodule Recurse do
  @moduledoc """
  Functions that have to be defined in a module in order to recurse.
  """

  @doc "Find all logic chains that end in A."
  @spec chains(String.t, map) :: list
  def chains(label, data) when is_map_key(data, label) do
    rules = Map.fetch!(data, label)
    Enum.flat_map_reduce(rules, [], fn %{test: t, dest: d}, chain ->
      nxt_chain = [{true, t} | chain]  # true = this test failed
      t = if is_nil(t), do: t, else: {false, t}
      if d in ~w(A R)s, do: {[[d, t] ++ chain], nxt_chain},
      else: {Enum.map(chains(d, data), &(&1 ++ [t | chain])), nxt_chain}
    end) |> elem(0) |> Enum.filter(&(hd(&1) == "A"))
  end
end
