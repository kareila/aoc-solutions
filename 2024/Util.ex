defmodule Util do
  @moduledoc """
  Library of frequently used functions, for convenience.
  """

  @doc "Return a list of matches for the provided pattern."
  @spec all_matches(String.t, Regex.t) :: [String.t]
  def all_matches(str, pat) do
    Regex.scan(pat, str, capture: :all_but_first) |> Enum.concat
  end

  @doc "Return a list of integers from the given string."
  @spec read_numbers(String.t) :: [integer]
  def read_numbers(str) do
    all_matches(str, ~r/(-?\d+)/) |> Enum.map(&String.to_integer/1)
  end

  @doc "Return the Manhattan distance between two coordinate tuples."
  @spec m_dist(tuple, tuple) :: integer
  def m_dist(tup1, tup2) when is_tuple(tup1) and is_tuple(tup2) do
    Enum.map([tup1, tup2], &Tuple.to_list/1) |>
    Enum.zip_with(fn [t1, t2] -> abs(t1 - t2) end) |> Enum.sum
  end

  @doc "Return the four coordinate tuples adjacent to this position."
  @spec adj_pos({integer, integer}) :: [tuple]
  def adj_pos({x, y}) when is_integer(x) and is_integer(y) do
    [{x - 1, y}, {x + 1, y}, {x, y - 1}, {x, y + 1}]
  end

  @doc "Return the eight coordinate tuples surrounding this position."
  @spec sur_pos({integer, integer}) :: [tuple]
  def sur_pos({x, y}) when is_integer(x) and is_integer(y) do
    [{x - 1, y - 1}, {x - 1, y}, {x - 1, y + 1}, {x, y - 1},
     {x + 1, y - 1}, {x + 1, y}, {x + 1, y + 1}, {x, y + 1}]
  end

  @doc "Map the compass points to the values of adj_pos."
  @spec dir_pos({integer, integer}) :: map
  def dir_pos(pos) when is_tuple(pos) do  # (y decreases upward)
    Enum.zip(~w(W E N S), adj_pos(pos)) |> Map.new
  end

  @doc "Transform a list into a map using index values as keys."
  @spec list_to_map(list, integer) :: map
  def list_to_map(list), do: list_to_map(list, 0)
  def list_to_map(list, idx) when is_list(list) do
    Enum.with_index(list, idx) |> Map.new(fn {v, i} -> {i, v} end)
  end

  @doc "Group tuples by position."
  @spec group_tuples([tuple], integer) :: map
  def group_tuples(data, i), do: Enum.group_by(data, &elem(&1,i))
  def group_tuples(data, i, j) do
    Enum.group_by(data, &elem(&1,i), &elem(&1,j))
  end

  @doc "Convert a hexadecimal digit to a 4 bit binary digit."
  @spec hex_digit_to_binary(String.t | integer) :: String.t
  def hex_digit_to_binary(c) do
    Integer.parse(c, 16) |> elem(0) |> # decimal value of hex digit
    Integer.digits(2) |> Enum.join |>  # binary value as string
    String.pad_leading(4, "0")         # fixed width of 4 bits
  end

end
