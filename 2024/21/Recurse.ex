defmodule Recurse do
  @moduledoc """
  Functions that have to be defined in a module in order to recurse.
  """

  @doc "Drill down recursively to find the desired value from the data."
  @spec pair_value({any, any}, map) :: {pos_integer, map}
  def pair_value({start, goal}, data) do
    if is_nil(data.limit), do: raise(RuntimeError, "no defined limit")
    prev_lvl = Enum.max([data.lvl - 1, 0])
    cond do
      data.lvl > data.limit or start == goal ->
        {1, %{data | lvl: prev_lvl}}
      is_map_key(data.cache, {start, goal, data.lvl}) ->
        {data.cache[{start, goal, data.lvl}], %{data | lvl: prev_lvl}}
      true ->
        keypad = data.keypad.(data)
        found =
          Enum.reduce_while(Stream.cycle([1]), [[start]], fn _, paths ->
            nxt =
              Enum.flat_map(paths, fn p ->
                [pos | paths] = p
                Enum.map(keypad[pos], fn {dir, v} -> {v, [dir | paths]} end)
              end)
            vals = Util.group_tuples(nxt, 0, 1)
            if is_map_key(vals, goal) do
              {:halt, Enum.map(vals[goal], &Enum.reverse(["A" | &1]))}
            else
              {:cont, Enum.map(nxt, fn {k, v} -> [k | v] end)}
            end
          end) |> Enum.map(data.form_pairs)
        {vals, data} =
          Enum.map_reduce(found, data, fn list, data ->
            Enum.map_reduce(list, data, fn pair, data ->
              pair_value(pair, %{data | lvl: data.lvl + 1})
            end)
          end)
        tot = Enum.map(vals, &Enum.sum/1) |> Enum.min
        cache = Map.put(data.cache, {start, goal, data.lvl}, tot)
        {tot, %{data | cache: cache, lvl: prev_lvl}}
    end
  end
end
