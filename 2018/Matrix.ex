defmodule Matrix do
  @moduledoc """
  Library of functions for 2D mapping.
  """

  @doc "Parses input into a list of three element tuples."
  @spec grid([String.t]) :: [tuple]
  def grid(lines) do
    for {line, y} <- Enum.with_index(lines),
        {v, x} <- String.graphemes(line) |> Enum.with_index,
    do: {x, y, v}
  end

  @doc "Parses input as a map of values with coordinates as keys."
  @spec map([String.t] | [tuple]) :: map
  def map(lines) do
    data = if Enum.all?(lines, &is_tuple/1), do: lines, else: grid(lines)
    for {x, y, v} <- data, into: %{}, do: { {x, y}, v }
  end

  @doc "Returns a list of grid values grouped into rows."
  @spec order_points([tuple] | map) :: [list]
  def order_points(grid) when is_map(grid), do:
    Map.keys(grid) |> order_points
  def order_points(grid) when is_list(grid) do
    List.keysort(grid, 0) |> Enum.group_by(&elem(&1,1)) |>
    Map.to_list |> List.keysort(0) |> Enum.map(&elem(&1,1))
  end

  @doc "Prints an ASCII rendering of a grid map. Best used with IO.puts."
  @spec print_map(map) :: String.t
  def print_map(m_map) do
    Enum.map_join(order_points(m_map), "\n",
      fn row -> Enum.map_join(row, &Map.fetch!(m_map, &1))
    end)
  end

  @doc "Prints an ASCII rendering of a sparse map. Best used with IO.puts."
  @spec print_sparse_map(map) :: String.t
  def print_sparse_map(data) do
    {xmin, xmax, ymin, ymax} = limits(data)
    Enum.map_join(ymin..ymax, "\n", fn j ->
      Enum.map_join(xmin..xmax, fn i -> Map.get(data, {i, j}, ".") end)
    end)
  end

  @doc "List the dimensions of a grid: x_min, x_max, y_min, y_max."
  @spec limits([tuple] | map) :: {integer, integer, integer, integer}
  def limits(grid) when is_map(grid), do: Map.keys(grid) |> limits
  def limits(grid) when is_list(grid) do
    [min_max_x(grid), min_max_y(grid)] |>
    Enum.flat_map(&Tuple.to_list/1) |> List.to_tuple
  end

  @doc "Finds the minimum and maximum X coordinate from a list of tuples."
  @spec min_max_x([tuple]) :: {integer, integer}
  def min_max_x(points), do: minmax(points, 0)

  @doc "Finds the minimum and maximum Y coordinate from a list of tuples."
  @spec min_max_y([tuple]) :: {integer, integer}
  def min_max_y(points), do: minmax(points, 1)

  defp minmax(points, i), do: Enum.map(points, &elem(&1,i)) |> Enum.min_max
end
