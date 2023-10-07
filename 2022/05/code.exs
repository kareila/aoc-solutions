# Solution to Advent of Code 2022, Day 5
# https://adventofcode.com/2022/day/5

Code.require_file("Util.ex", "..")

# returns a pair of blocks from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n\n", trim: true)
end

# Example data:
#     [D]
# [N] [C]
# [Z] [M] [P]
#  1   2   3
#
# move 1 from 2 to 1
# move 3 from 1 to 3
# move 2 from 2 to 1
# move 1 from 1 to 2

parse_stacks = fn lines ->
  {rows, [nums]} = String.split(lines, "\n", trim: true) |> Enum.split(-1)
  num_stacks = Util.read_numbers(nums) |> List.last
  stack_pat = List.duplicate(".(.).", num_stacks) |> Enum.join(" ")
  for(r <- rows, s = Util.all_matches(r, ~r"#{stack_pat}"),
      {x, i} <- Enum.with_index(s, 1), x != " ", do: {i, x})
  |> Util.group_tuples(0, 1)
end

parse_moves = fn lines ->
  String.split(lines, "\n", trim: true) |> Enum.map(&Util.read_numbers/1)
end

parse_input = fn [stacks, moves] ->
  {parse_stacks.(stacks), parse_moves.(moves)}
end

{data, moves} = read_input.() |> parse_input.()

get_tops = fn data ->
  Enum.sort(data) |> Enum.map_join(fn {_, v} -> hd(v) end)
end

do_stack = fn list, stack -> Enum.reverse(list) ++ stack end

do_moves = fn stack_fn ->
  Enum.reduce(moves, data, fn [n, src, dst], data ->
    {take, leave} = Enum.split(data[src], n)
    dst_stack = stack_fn.(take, data[dst])
    data |> Map.put(src, leave) |> Map.put(dst, dst_stack)
  end)
end

IO.puts("Part 1: #{do_moves.(do_stack) |> get_tops.()}")


# For the second part, move multiple crates at once.
new_stack = fn list, stack -> list ++ stack end

IO.puts("Part 2: #{do_moves.(new_stack) |> get_tops.()}")
