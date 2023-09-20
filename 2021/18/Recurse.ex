defmodule Recurse do
  @moduledoc """
  Functions that have to be defined in a module in order to recurse.
  """

  @doc "Fully reduce a data structure according to the provided rules."
  @spec reduce([any()], fun, fun) :: [any()]
  def reduce(data, f_explode, f_split) do
    data =
      Enum.reduce_while(Stream.cycle([1]), data, fn _, data ->
        d_exploded = f_explode.(data)
        if is_nil(d_exploded), do: {:halt, data},
        else: {:cont, d_exploded}
      end)
    d_split = f_split.(data)
    if is_nil(d_split), do: data, else: reduce(d_split, f_explode, f_split)
  end

  @doc "Recursively calculate the magnitude of a data structure."
  @spec magnitude([any()]) :: integer
  def magnitude([pl, pr]) do
    ret = if is_list(pl), do: 3 * magnitude(pl), else: 3 * pl
    ret + if is_list(pr), do: 2 * magnitude(pr), else: 2 * pr
  end
end
