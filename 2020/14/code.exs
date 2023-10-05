# Solution to Advent of Code 2020, Day 14
# https://adventofcode.com/2020/day/14

Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

as_binary = fn n ->
  Integer.digits(n, 2) |> Enum.join |> String.pad_leading(36, "0")
end

as_decimal = fn b -> Integer.parse(b, 2) |> elem(0) end

parse_input = fn lines ->
  Enum.flat_map_reduce(lines, nil, fn line, active_mask ->
    match = Regex.run(~r/^mask = (\S+)$/, line)
    cond do
      is_nil(match) and is_nil(active_mask) -> raise RuntimeError
      is_nil(match) ->
        [k, v] = Util.read_numbers(line)
        {[{active_mask, k, v}], active_mask}
      true -> {[], Enum.at(match, 1)}
    end
  end) |> elem(0)
end

data = read_input.() |> parse_input.()

mask_zip = fn mask, v, keep_b ->
  String.graphemes(as_binary.(v)) |> Enum.zip_reduce(String.graphemes(mask),
  "", fn b, m, s -> s <> if m == keep_b, do: b, else: m end)
end

pt1 =
   Map.new(data, fn {mask, k, v} -> {k, mask_zip.(mask, v, "X")} end) |>
   Map.values |> Enum.map(as_decimal) |> Enum.sum

IO.puts("Part 1: #{pt1}")


addr_mask = fn mask, k ->
  do_r = fn s, v -> String.replace(s, "X", "#{v}", global: false) end
  both = fn a -> Enum.flat_map(a, &[do_r.(&1, 0), do_r.(&1, 1)]) end
  Enum.reduce_while(Stream.cycle([1]), [mask_zip.(mask, k, "0")], fn _, a ->
    if String.contains?(hd(a), "X"), do: {:cont, both.(a)}, else: {:halt, a}
  end)
end

pt2 =
  Enum.map(data, fn {mask, k, v} -> Map.from_keys(addr_mask.(mask, k), v)
  end) |> Enum.reduce(&Map.merge(&2, &1)) |> Map.values |> Enum.sum

IO.puts("Part 2: #{pt2}")
