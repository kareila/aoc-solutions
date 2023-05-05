defmodule Recurse do
  @moduledoc """
  Functions that have to be defined in a module in order to recurse.
  """

  @doc "Return true for ordered, false for disordered, nil if identical."
  @spec check_pair(pair :: tuple()) :: boolean()
  def check_pair(pair) when is_tuple(pair) do
    # We don't care about the loop values, just don't exit until halted.
    Enum.reduce_while(Stream.cycle([1]), pair,
      fn _, {pl, pr} -> compare(pl, pr) end)
  end
  def check_pair(_),  do: raise ArgumentError

  @spec compare(list, list) :: {:halt, boolean} | {:cont, tuple}
  def compare([], []), do: {:halt, nil}
  def compare([], _),  do: {:halt, true}
  def compare(_, []),  do: {:halt, false}

  def compare([left | pl], [right | pr])
      when is_integer(left) and is_integer(right) do
    cond do
      left < right -> {:halt, true}
      left > right -> {:halt, false}
      true -> {:cont, {pl, pr}}
    end
  end

  def compare([left | pl], [right | pr]) do
    pair = cond do
      is_list(left) and is_list(right) -> {left, right}
      is_list(left) -> {left, [right]}
      true -> {[left], right}
    end
    result = check_pair(pair)
    if result != nil, do: {:halt, result}, else: {:cont, {pl, pr}}
  end

  def compare(_, _),  do: raise ArgumentError
end
