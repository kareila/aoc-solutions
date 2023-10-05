defmodule Recurse do
  @moduledoc """
  Functions that have to be defined in a module in order to recurse.
  """

  @doc "Recursively search bags containing other bags."
  @spec unpack(String.t, String.t, map, map) :: map
  def unpack(top, unpacked, rules), do: unpack(top, top, unpacked, rules)

  def unpack(top, top, unpacked, _) when is_map_key(unpacked, top),
    do: unpacked

  def unpack(top, top, unpacked, rules) do
    if is_nil(rules[top]), do: Map.put(unpacked, top, %{}),
    else: dig(top, top, unpacked, rules)
  end

  def unpack(top, bag, unpacked, rules) when not is_map_key(unpacked, bag),
    do: dig(top, bag, unpacked, rules)

  def unpack(top, bag, unpacked, rules) do
    unpacked = Map.put_new(unpacked, top, rules[top])
    Map.put(unpacked, top, m_merge(unpacked[top], unpacked[bag]))
  end

  defp m_merge(m1, m2), do: Map.merge(m1, m2, fn _, v1, v2 -> v1 + v2 end)

  defp dig(top, bag, unpacked, rules) do
    Enum.reduce(rules[bag], unpacked, fn {i, n}, unpacked ->
      Enum.reduce(1..n, unpack(i, unpacked, rules), fn _, unpacked ->
        unpack(top, i, unpacked, rules)
      end)
    end)
  end
end
