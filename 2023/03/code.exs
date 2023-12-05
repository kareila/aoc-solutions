# Solution to Advent of Code 2023, Day 3
# https://adventofcode.com/2023/day/3

Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# combine regex match with its offset in the string
parse_pat = fn pat, str ->
  Regex.scan(pat, str, return: :index) |>
  Enum.map(fn [{idx, sz}] -> {idx, binary_slice(str, idx, sz)} end)
end

parse_for_nums = fn line ->
  parse_pat.(~r/[0-9]+/, line) |>
  Enum.map(fn {i, n} -> {i, String.to_integer(n)} end)
end

parse_lines = fn lines ->
  Enum.flat_map(Enum.with_index(lines), fn {line, y} ->
    Enum.concat(parse_for_nums.(line), parse_pat.(~r/[^0-9.]/, line)) |>
    Enum.map(fn {x, v} -> {{x, y}, v} end)
  end)
end

# after calculating all coordinates, segregate numbers and symbols
parse_data = fn data ->
  {nums, syms} = Enum.split_with(data, fn {_, v} -> is_integer(v) end)
  %{nums: nums, syms: Map.new(syms)}
end

# this can also contain the spaces occupied by the number but that's ok
coords_to_check = fn {{x_min, y}, n} ->
  x_max = length(Integer.digits(n)) + x_min - 1
  Enum.flat_map(x_min..x_max, fn x -> Util.sur_pos({x, y}) end) |> Enum.uniq
end

adj_symbol? = fn p, sym_map ->
  Enum.any?(coords_to_check.(p), fn xy -> is_map_key(sym_map, xy) end)
end

part_numbers = fn %{nums: nums, syms: syms} ->
  Enum.filter(nums, &adj_symbol?.(&1, syms)) |> Enum.map(&elem(&1, 1))
end

data = read_input.() |> parse_lines.() |> parse_data.()

IO.puts("Part 1: #{part_numbers.(data) |> Enum.sum}")


gear_locs = fn syms -> Util.group_tuples(syms, 1, 0) |> Map.get("*") end

get_adj_numbers = fn %{nums: nums, syms: syms} ->
  coords = Enum.map(nums, fn {xy, n} -> {n, coords_to_check.({xy, n})} end)
  Enum.map(gear_locs.(syms), fn p ->
    Enum.filter(coords, fn {_, v} -> p in v end) |> Enum.map(&elem(&1, 0))
  end)
end

gear_ratios = fn data ->
  Enum.filter(get_adj_numbers.(data), fn v -> length(v) == 2 end) |>
  Enum.map(&Enum.product/1)
end

IO.puts("Part 2: #{gear_ratios.(data) |> Enum.sum}")
