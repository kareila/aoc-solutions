defmodule Recurse do
  @moduledoc """
  Functions that have to be defined in a module in order to recurse.
  """

  @doc "Compute values by traversing a binary tree."
  @spec calc(String.t, map) :: integer
  def calc(key, data) when is_map_key(data, key) do
    monkey = data[key]
    if Map.has_key?(monkey, :num), do: monkey.num,
    else: monkey.op.( calc(monkey.a, data), calc(monkey.b, data) )
  end

  def calc(key, _), do: raise ArgumentError, "Key #{key} not found"

  @doc "Search for a value's path in a binary tree."
  @spec search([String.t], String.t, map) :: [String.t] | nil
  def search([], _, _), do: raise ArgumentError, "Need a starting node"

  def search([name | branch], name, _), do: [name | branch]

  def search([name | branch], target, data) when is_map_key(data, name) do
    monkey = data[name]
    if Map.has_key?(monkey, :num) do []
    else
      branch = [name | branch]
      [[monkey.a | branch], [monkey.b | branch]]
      |> Enum.flat_map(&search(&1, target, data))
    end
  end

  def search([k | _], _, _), do: raise ArgumentError, "Key #{k} not found"
end
