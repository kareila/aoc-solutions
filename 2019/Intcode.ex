defmodule Intcode do
  @moduledoc """
  Functions for parsing and executing Intcode programs,
  as found in the exercises for Advent of Code 2019.
  """

  defp padded_replace(list_map, pos, val), do: Map.put(list_map, pos, val)

  defp next_vals(nums, pos) do
    Enum.map(pos..(pos + 4), fn i -> Map.get(nums, i, 0) end)
  end

  defp parse_opcode(state) do
    [opcode | vals] = next_vals(state.nums, state.pos)
    {modes, opc} = Integer.digits(opcode) |> Enum.split(-2)
    {Integer.undigits(opc), Enum.reverse(modes), vals}
  end

  defp parse_param(param, %{nums: nums, modes: modes, r_base: r_base}) do
    Enum.map(param |> Enum.with_index, fn {pos, m_i} ->
      case Enum.at(modes, m_i, 0) do
        0 -> Map.get(nums, pos, 0)
        1 -> pos
        2 -> Map.get(nums, pos + r_base, 0)
      end
    end)
  end

  defp parse_offset(m_i, %{modes: modes, r_base: r_base}) do
    case Enum.at(modes, m_i, 0) do
      0 -> 0
      1 -> raise ArgumentError  # mode 1 is invalid for offset
      2 -> r_base
    end
  end

  defp math_op([pos_i1, pos_i2, pos_out], data, op) do
    [i1, i2] = parse_param([pos_i1, pos_i2], data)
    pos_out = pos_out + parse_offset(2, data)
    padded_replace(data.nums, pos_out, op.(i1, i2))
  end

  defp input_op([pos_out], data, input) do
    pos_out = pos_out + parse_offset(0, data)
    padded_replace(data.nums, pos_out, input)
  end

  defp output_op(pos, data), do: data.output ++ parse_param(pos, data)

  defp jump_op([pos_t, pos_p], data, cur_pos, op) do
    [t, p] = parse_param([pos_t, pos_p], data)
    if op.(t, 0), do: p, else: cur_pos
  end

  defp bool_op([pos_i1, pos_i2, pos_out], data, op) do
    [i1, i2] = parse_param([pos_i1, pos_i2], data)
    pos_out = pos_out + parse_offset(2, data)
    val = if op.(i1, i2), do: 1, else: 0
    padded_replace(data.nums, pos_out, val)
  end

  defp rebase_op(pos, data) do
    parse_param(pos, data) |> hd |> then(&(&1 + data.r_base))
  end

  @doc """
  Execute a program step. Initial state format is:
    %{pos: 0, nums: data, output: [], r_base: 0}
  where 'data' is the compiled Intcode program.
  """
  @spec prog_step(input :: any, state :: map) :: {integer, map}
  def prog_step(input, state) do
    {opcode, modes, vals} = parse_opcode(state)
    data = Map.put(state, :modes, modes)
    state =
      case opcode do
        1 -> %{state | pos: state.pos + 4, nums: Enum.take(vals, 3)
                     |> math_op(data, &+/2)}
        2 -> %{state | pos: state.pos + 4, nums: Enum.take(vals, 3)
                     |> math_op(data, &*/2)}
        3 -> %{state | pos: state.pos + 2, nums: Enum.take(vals, 1)
                     |> input_op(data, input)}
        4 -> %{state | pos: state.pos + 2, output: Enum.take(vals, 1)
                     |> output_op(data)}
        5 -> %{state | pos: Enum.take(vals, 2)
                     |> jump_op(data, state.pos + 3, &!=/2)}
        6 -> %{state | pos: Enum.take(vals, 2)
                     |> jump_op(data, state.pos + 3, &==/2)}
        7 -> %{state | pos: state.pos + 4, nums: Enum.take(vals, 3)
                     |> bool_op(data, &</2)}
        8 -> %{state | pos: state.pos + 4, nums: Enum.take(vals, 3)
                     |> bool_op(data, &==/2)}
        9 -> %{state | pos: state.pos + 2, r_base: Enum.take(vals, 1)
                     |> rebase_op(data)}
        99 -> state
      end
    {opcode, state}
  end
end
