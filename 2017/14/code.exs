# Solution to Advent of Code 2017, Day 14
# https://adventofcode.com/2017/day/14

require KnotHash  # for hash()

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

row_inputs = fn str ->
  Range.to_list(0..127) |> Map.from_keys(str) |> Map.to_list |>
  List.keysort(0) |> Enum.map(fn {i, s} -> "#{s}-#{i}" end)
end

parse_digit = fn c ->
  Integer.parse(c, 16) |> elem(0) |> # decimal value of hex digit
  Integer.digits(2) |> Enum.join |>  # binary value as string
  String.pad_leading(4, "0")         # fixed width of 4 bits
end

parse_hash = fn s -> Enum.map_join(String.graphemes(s), parse_digit) end

# Need to reuse the Part 2 solution from Day 10. Since it's kind of
# a lot of code, I'm moving it to a module. Running it 128 times in
# a row takes about 1.5 seconds, so using async calculations...
start_task = fn row -> Task.async(fn -> KnotHash.hash(row) end) end

data = read_input.() |> hd |> row_inputs.() |> Enum.map(start_task) |>
       Enum.map(&Task.await/1) |> Enum.with_index |>
       Enum.reduce(MapSet.new, fn {row, j}, used ->
         parse_hash.(row) |> String.graphemes |> Enum.with_index |>
         Enum.flat_map(fn {b, i} -> if b == "1", do: [i], else: [] end) |>
         Enum.reduce(used, fn i, used -> MapSet.put(used, {i, j}) end)
       end)

IO.puts("Part 1: #{MapSet.size(data)}")


adj_pos = fn {x, y} -> [{x - 1, y}, {x + 1, y}, {x, y - 1}, {x, y + 1}] end
used? = fn pos -> MapSet.member?(data, pos) end

# ... and we can reuse our Part 2 solution from Day 12 here...
find_group = fn pos ->
  Enum.reduce_while(Stream.cycle([1]), MapSet.new([pos]), fn _, found ->
    nxt = Enum.flat_map(found, adj_pos) |> Enum.filter(used?) |>
          MapSet.new |> MapSet.union(found)
    if MapSet.equal?(nxt, found), do: {:halt, found}, else: {:cont, nxt}
  end)
end

count_groups = fn all_used ->
  Enum.reduce_while(Stream.iterate(1, &(&1 + 1)), {all_used, MapSet.new},
  fn n, {search, found} ->
    found = MapSet.union(found, find_group.(hd(Enum.take(search, 1))))
    if MapSet.equal?(all_used, found), do: {:halt, n},
    else: {:cont, {MapSet.difference(all_used, found), found}}
  end)
end

IO.puts("Part 2: #{count_groups.(data)}")
