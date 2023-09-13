defmodule Recurse do
  @moduledoc """
  Functions that have to be defined in a module in order to recurse.
  """

  @dir %{"N" => {0, -1}, "S" => {0, 1}, "E" => {1, 0}, "W" => {-1, 0}}

  @doc "Map a branching series of cardinal directions."
  @spec traverse([String.t], integer, integer, map) :: map
  def traverse(input, pos \\ {0, 0}, depth \\ 0, data \\ %{}) do
    data = Map.put_new(data, pos, depth)
    init = %{pos: pos, depth: depth}
    Enum.reduce_while(Stream.cycle([1]), {input, pos, depth, data},
    fn _, {input, pos, depth, data} ->
      [c | input] = input
      case c do
        "$" -> {:halt, data}
        ")" -> {:halt, {input, pos, depth, data}}
        "(" -> {:cont, traverse(input, pos, depth, data)}
        "|" -> {:cont, {input, init.pos, init.depth, data}}
        c when is_map_key(@dir, c) ->
          {:cont, step(input, pos, @dir[c], depth, data)}
      end
    end)
  end

  defp step(input, {px, py}, {dx, dy}, depth, data) do
    pos = {px + dx, py + dy}
    if Map.has_key?(data, pos), do: {input, pos, data[pos], data},
    else: {input, pos, depth + 1, Map.put(data, pos, depth + 1)}
  end
end
