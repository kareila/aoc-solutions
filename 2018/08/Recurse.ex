defmodule Recurse do
  @moduledoc """
  Functions that have to be defined in a module in order to recurse.
  """

  @doc "Parse a list of digits into nodes."
  @spec nodes([integer]) :: map | tuple
  def nodes(digits) do
    {[cnum, mnum], digits} = Enum.split(digits, 2)
    {digits, children} =
      Enum.reduce(1..cnum//1, {digits, []}, fn _, {digits, children} ->
        {digits, child} = nodes(digits)
        {digits, children ++ [child]}
      end)
    {metadata, digits} = Enum.split(digits, mnum)
    this = %{children: children, metadata: metadata}
    if Enum.empty?(digits), do: this, else: {digits, this}
  end

  @doc "Sum the node values of the given tree."
  @spec node_sum(map, integer) :: integer
  def node_sum(%{children: children, metadata: metadata}, 1) do
    Enum.reduce(children, 0, fn n, tot -> tot + node_sum(n, 1) end) + Enum.sum(metadata)
  end

  def node_sum(%{children: children, metadata: metadata}, 2) do
    if Enum.empty?(children), do: Enum.sum(metadata), else:
    Enum.reject(metadata, &(&1 == 0)) |>
    Enum.reduce(0, fn i, total ->
      val = Enum.at(children, i - 1)
      total + if(val, do: node_sum(val, 2), else: 0)
    end)
  end
end
