defmodule KnotHash do
  @moduledoc """
  Code for so-called knot hash value calculation.
  """

  @doc "Compute the knot hash value."
  @spec hash(String.t) :: String.t
  def hash(str) do
    init_state(str, 256) |> do_64() |> Enum.chunk_every(16) |>
    Enum.map(fn c -> Enum.reduce(c, &Bitwise.bxor/2) end) |>
    Enum.map_join(&convert_to_hex/1)
  end

  defp init_list(len), do: Map.new(1..len, fn i -> {i - 1, i - 1} end)
  defp init_ascii(str), do: String.to_charlist(str) ++ [17, 31, 73, 47, 23]
  defp init_state(row, len), do:
    %{lengths: init_ascii(row), list: init_list(len), pos: 0, skip: 0}
  defp mod_size(n, list), do: Integer.mod(n, map_size(list))
  defp convert_to_hex(num), do: Integer.digits(num, 16) |>
    Enum.map_join(&hex_translate/1) |> String.pad_leading(2, "0")
  defp hex_translate(digit) do
    %{10 => "a", 11 => "b", 12 => "c", 13 => "d", 14 => "e", 15 => "f"} |>
    Map.get(digit, digit)
  end

  defp do_all(state), do:
    Enum.reduce(1..length(state.lengths), state, fn _, s -> step(s) end)
  defp do_64(state) do
    Enum.reduce(1..64, state, fn _, state ->
      %{do_all(state) | lengths: state.lengths}
    end) |> Map.fetch!(:list) |> Enum.sort |> Enum.map(&elem(&1,1))
  end

  defp step(%{list: list, pos: pos, skip: skip} = state) do
    [len | rest] = state.lengths
    range = if len < 2, do: [],
            else: Enum.map(pos..(pos + len - 1), &mod_size(&1, list))
    seg = Enum.map(range, &Map.fetch!(list, &1)) |> Enum.reverse
    list = Map.merge(list, Map.new(Enum.zip(range, seg)))
    pos = mod_size(pos + len + skip, list)
    %{lengths: rest, list: list, pos: pos, skip: skip + 1}
  end
end
