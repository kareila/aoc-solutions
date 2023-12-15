defmodule Recurse do
  @moduledoc """
  Functions that have to be defined in a module in order to recurse.
  """

  @doc "Count possible matches for a string pattern."
  @spec p_count([String.t], [integer], integer, map) :: {integer, map}
  def p_count(chrs, chk, run_num \\ 0, cache \\ %{})

  def p_count([], [], 0, cache), do: {1, cache}
  def p_count([], [n], n, cache), do: {1, cache}
  def p_count([], _, _, cache), do: {0, cache}

  def p_count(chrs, chk, run_num, cache) do
    c_key = {chrs, chk, run_num}
    if is_map_key(cache, c_key) do {cache[c_key], cache}
    else
      abort = fn -> {0, Map.put(cache, c_key, 0)} end
      possible_more = Enum.count(chrs, &(&1 in ["#", "?"]))
      [curr | chrs] = chrs
      cond do
        possible_more + run_num < Enum.sum(chk) -> abort.()
        run_num > 0 and Enum.empty?(chk) -> abort.()
        run_num > 0 and curr == "." and run_num != hd(chk) -> abort.()
        true ->
          {poss1, cache} =
            if curr in [".", "?"] and run_num == List.first(chk),
            do: p_count(chrs, tl(chk), 0, cache), else: {0, cache}
          {poss2, cache} =
            if curr in [".", "?"] and run_num == 0,
            do: p_count(chrs, chk, 0, cache), else: {0, cache}
          {poss3, cache} =
            if curr in ["#", "?"],
            do: p_count(chrs, chk, run_num + 1, cache), else: {0, cache}
          poss = poss1 + poss2 + poss3
          {poss, Map.put(cache, c_key, poss)}
      end
    end
  end
end
