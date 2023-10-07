defmodule Recurse do
  @moduledoc """
  Functions that have to be defined in a module in order to recurse.
  """

  @doc "Compute values by traversing a binary tree."
  @spec calc(String.t, map) :: integer
  def calc(key, data) do
    monkey = Map.fetch!(data, key)
    if Map.has_key?(monkey, :num), do: monkey.num,
    else: monkey.op.( calc(monkey.a, data), calc(monkey.b, data) )
  end

  @doc "Search for a value's path in a binary tree."
  @spec search([String.t], String.t, map) :: [String.t]
  def search([], _, _), do: raise(ArgumentError, "Need a starting node")

  def search([name | branch], name, _), do: [name | branch]

  def search([name | branch], target, data) do
    monkey = Map.fetch!(data, name)
    if Map.has_key?(monkey, :num) do []
    else
      branch = [name | branch]
      [[monkey.a | branch], [monkey.b | branch]]
      |> Enum.flat_map(&search(&1, target, data))
    end
  end
end
