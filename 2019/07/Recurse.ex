defmodule Recurse do
  @moduledoc """
  Functions that have to be defined in a module in order to recurse.
  """

  @doc "Generate permutations of a list."
  @spec permutations(list) :: list
  def permutations([]), do: [[]]
  def permutations(list) do
    for item <- list, rest <- permutations(list -- [item]), do: [item | rest]
  end
end
