defmodule Recurse do
  @moduledoc """
  Functions that have to be defined in a module in order to recurse.
  """

  @doc "Search a bounded space for exposed surfaces."
  @spec search(tuple, MapSet.t, map, MapSet.t, non_neg_integer) :: tuple
  def search({x,y,z}, data, limits, visited, ct) do
    f = [{x-1,y,z}, {x+1,y,z}, {x,y-1,z}, {x,y+1,z}, {x,y,z-1}, {x,y,z+1}]
    cond do
      x < limits.min_x or x > limits.max_x -> {visited, ct}
      y < limits.min_y or y > limits.max_y -> {visited, ct}
      z < limits.min_z or z > limits.max_z -> {visited, ct}
      MapSet.member?(visited, {x,y,z}) -> {visited, ct}
      true ->
        visited = MapSet.put(visited, {x,y,z})
        Enum.reduce(f, {visited, ct}, fn face, {visited, ct} ->
          if MapSet.member?(data, face), do: {visited, ct + 1},
          else: search(face, data, limits, visited, ct)
        end)
    end
  end
end
