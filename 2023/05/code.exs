# Solution to Advent of Code 2023, Day 5
# https://adventofcode.com/2023/day/5

Code.require_file("Util.ex", "..")

# returns a list of non-blank BLOCKS from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n\n", trim: true)
end

parse_block = fn block ->
  [_, b] = String.split(block, ":")
  String.split(b, "\n", trim: true) |> Enum.map(&Util.read_numbers/1)
end

# Large lists of consecutive integers should use Range objects.
parse_range = fn [d, s, len] -> {s..(s + len - 1), d - s} end

# We are allowed to use the Range objects as Map keys.
parse_map = fn list -> Map.new(list, parse_range) end

# Easier to reuse code if we treat each seed as a Range of length 1.
pt1_seeds = fn seeds -> Enum.map(seeds, fn s -> s..s end) end

parse_data = fn blocks, seed_fn ->
  [[seeds] | maps] = Enum.map(blocks, parse_block)
  %{seeds: seed_fn.(seeds), maps: Enum.map(maps, parse_map)}
end

# Determine how the given map applies to the given range of seeds.
# This becomes tricky: we need to carefully track which seeds get
# shifted by some aspect of the map, and which do not. But we can
# be confident that the map only applies once to any given seed.
check_range = fn s, m ->
  Enum.reject(Map.keys(m), &Range.disjoint?(&1, s)) |>
  Enum.map(fn r ->
    b = Enum.max([s.first, r.first])
    e = Enum.min([s.last, r.last])
    # just the shifted segment, paired with its original values
    {Range.shift(b..e, m[r]), b..e}
  end)
end

# Create a list of 0-2 ranges that remain when removing a subset range.
remove_subset = fn r, s ->
  r1 = Range.new(s.first, Enum.max([s.first, r.first]) - 1, 1)
  r2 = Range.new(Enum.min([s.last, r.last]) + 1, s.last, 1)
  Enum.reject([r1, r2], &(Range.size(&1) == 0))
end

# Remove all applicable subsets from a single range.
process_removals = fn list, s ->
  Enum.reduce(list, [s], fn {_, r}, set ->
    Enum.reject(set, &Range.disjoint?(&1, r)) |>
    Enum.flat_map(&remove_subset.(r, &1))
  end)
end

# Combine the shifted and unshifted range values.
map_results = fn rs, s ->
  Enum.map(rs, &elem(&1, 0)) ++ Enum.flat_map(s, &process_removals.(rs, &1))
end

# Given a range of seeds, apply the list of maps in order.
map_seed = fn seed_range, maps ->
  Enum.reduce(maps, [seed_range], fn m, s ->
    nxt = Enum.flat_map(s, &check_range.(&1, m))
    if Enum.empty?(nxt), do: s, else: map_results.(nxt, s)
  end)
end

find_lowest = fn data ->
  Enum.flat_map(data.seeds, &map_seed.(&1, data.maps)) |>
  Enum.map(&(&1.first)) |> Enum.min
end

IO.puts("Part 1: #{read_input.() |> parse_data.(pt1_seeds) |> find_lowest.()}")


pt2_seeds = fn seeds ->
  Enum.chunk_every(seeds, 2) |>
  Enum.map(fn [s, len] -> Range.new(s, s + len - 1) end)
end

IO.puts("Part 2: #{read_input.() |> parse_data.(pt2_seeds) |> find_lowest.()}")
