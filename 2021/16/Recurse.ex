defmodule Recurse do
  @moduledoc """
  Functions that have to be defined in a module in order to recurse.
  """

  @doc "Decode a packet that may contain other packets."
  @spec decode_packet(String.t) :: map
  def decode_packet(input) do
    if not Regex.match?(~r/^[01]+$/, input),
       do: raise(ArgumentError, "not binary input")

    # the first three bits encode the packet version
    {ver, input} = String.split_at(input, 3)
    version = as_decimal(ver)

    # the next three bits encode the packet type ID
    {tid, input} = String.split_at(input, 3)
    type_id = as_decimal(tid)

    {value, input} =
      if type_id == 4 do  # numeric value
        Enum.reduce_while(Stream.cycle([1]), {"", input},
        fn _, {value, input} ->
          {nxt, input} = String.split_at(input, 5)
          {continue, nxt} = String.split_at(nxt, 1)
          if continue == "1", do: {:cont, {value <> nxt, input}},
          else: {:halt, {as_decimal(value <> nxt), input}}
        end)
      else
        {length_tid, input} = String.split_at(input, 1)
        if length_tid == "1" do
          # the next 11 bits represent the number of sub-packets
          {num_packets, input} = String.split_at(input, 11)
          Enum.reduce(1..as_decimal(num_packets), {[], input},
          fn _, {value, input} ->
            ret = decode_packet(input)
            {value ++ [ret], ret.input}
          end)
        else
          # the next 15 bits represent the total length in bits
          {len_packets, input} = String.split_at(input, 15)
          {substr, input} = String.split_at(input, as_decimal(len_packets))
          Enum.reduce_while(Stream.cycle([1]), {[], substr},
          fn _, {value, substr} ->
            ret = decode_packet(substr)
            if ret.input == "", do: {:halt, {value ++ [ret], input}},
            else: {:cont, {value ++ [ret], ret.input}}
          end)
        end
      end

    if is_list(value) do
      oper = %{
        0 => fn args -> Enum.sum(args) end,
        1 => fn args -> Enum.product(args) end,
        2 => fn args -> Enum.min(args) end,
        3 => fn args -> Enum.max(args) end,
        5 => fn [a, b] -> if a > b,  do: 1, else: 0 end,
        6 => fn [a, b] -> if a < b,  do: 1, else: 0 end,
        7 => fn [a, b] -> if a == b, do: 1, else: 0 end,
      } |> Map.fetch!(type_id)
      calcval = Enum.map(value, fn v -> v.value end) |> oper.()
      sub_sum = Enum.map(value, fn v -> v.version_sum end) |> Enum.sum
      %{version_sum: version + sub_sum, value: calcval, input: input}
    else
      %{version_sum: version, value: value, input: input}
    end
  end

  defp as_decimal(s), do: Integer.parse(s, 2) |> elem(0)
end
