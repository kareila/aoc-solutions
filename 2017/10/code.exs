# Solution to Advent of Code 2017, Day 10
# https://adventofcode.com/2017/day/10

Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

init_list = fn len -> Map.new(1..len, fn i -> {i - 1, i - 1} end) end

init_state = fn len, data_fn ->
  data = read_input.() |> hd |> data_fn.()
  %{lengths: data, list: init_list.(len), pos: 0, skip: 0}
end

init_data = fn input ->
  String.split(input, ",") |> Enum.map(&String.to_integer/1)
end

init_state1 = fn len -> init_state.(len, init_data) end

mod_size = fn n, list -> Integer.mod(n, map_size(list)) end

step = fn %{list: list, pos: pos, skip: skip} = state ->
  [len | rest] = state.lengths
  range = if len < 2, do: [],
          else: Enum.map(pos..(pos + len - 1), &mod_size.(&1, list))
  seg = Enum.map(range, &Map.fetch!(list, &1)) |> Enum.reverse
  list = Map.merge(list, Map.new(Enum.zip(range, seg)))
  pos = mod_size.(pos + len + skip, list)
  %{lengths: rest, list: list, pos: pos, skip: skip + 1}
end

do_all = fn state ->
  Enum.reduce(1..length(state.lengths), state, fn _, s -> step.(s) end)
end

final_product = fn state ->
  do_all.(state).list |> Map.take([0, 1]) |> Map.values |> Enum.product
end

IO.puts("Part 1: #{init_state1.(256) |> final_product.()}")


init_ascii = fn input ->
  String.to_charlist(input) ++ [17, 31, 73, 47, 23]
end

init_state2 = fn len -> init_state.(len, init_ascii) end

do_64 = fn state ->
  Enum.reduce(1..64, state, fn _, state ->
    %{do_all.(state) | lengths: state.lengths}
  end)
end

hex_translate = fn digit ->
  %{10 => "a", 11 => "b", 12 => "c", 13 => "d", 14 => "e", 15 => "f"} |>
  Map.get(digit, digit)
end

convert_to_hex = fn num ->
  Integer.digits(num, 16) |>
  Enum.map_join(hex_translate) |>
  String.pad_leading(2, "0")
end

knot_hash = fn state ->
  do_64.(state).list |> Enum.sort |>
  Enum.map(&elem(&1,1)) |> Enum.chunk_every(16) |>
  Enum.map(fn c -> Enum.reduce(c, &Bitwise.bxor/2) end) |>
  Enum.map_join(convert_to_hex)
end

IO.puts("Part 2: #{init_state2.(256) |> knot_hash.()}")
