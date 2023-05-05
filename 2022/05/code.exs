# Solution to Advent of Code 2022, Day 5
# https://adventofcode.com/2022/day/5

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# converts an input line to an integer (empty string is nil)
 s_to_int = fn line ->
   if line == "", do: nil, else: String.to_integer(line)
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
  {num_stacks, rows} = Enum.reduce_while(lines, [], fn line, rows ->
    cond do
      # Stack lines: append and continue
      line =~ ~r"\[" -> {:cont, [line | rows]}
      # Line of digits: halt and save the final digit
      line -> [_, num_stacks] = Regex.run(~r/\s(\d+)\s*$/, line)
              {:halt, {s_to_int.(num_stacks), Enum.reverse(rows)}}
    end
  end)
  stack_pat = List.duplicate(".(.).", num_stacks) |> Enum.join(" ")
  for(r <- rows, s = Regex.run(~r"#{stack_pat}", r) |> tl,
      {x, i} <- Enum.with_index(s,1), x != " ", do: {i, x})
  |> Enum.group_by(&elem(&1,0), &elem(&1,1))
end

parse_moves = fn lines ->
  move_lines = Enum.filter(lines, &String.starts_with?(&1, "move "))
  move_pat = ~r/(\d+) from (\d+) to (\d+)/
  Enum.map(move_lines, fn line ->
    Regex.run(move_pat, line) |> tl |> Enum.map(s_to_int)
  end)
end

data = read_input.() |> parse_stacks.()
moves = read_input.() |> parse_moves.()

get_tops = fn data -> Map.to_list(data) |>
  List.keysort(0) |> Enum.map_join(fn {_, v} -> hd(v) end)
end

do_stack = fn list, stack -> Enum.reverse(list) ++ stack end

do_moves = fn stack_fn ->
  Enum.reduce(moves, data, fn [n, src, dst], data ->
    {take, leave} = Enum.split(data[src], n)
    dst_stack = stack_fn.(take, data[dst])
    Map.put(data, src, leave) |> Map.put(dst, dst_stack)
  end)
end

IO.puts("Part 1: #{do_moves.(do_stack) |> get_tops.()}")


# For the second part, move multiple crates at once.
new_stack = fn list, stack -> list ++ stack end

IO.puts("Part 2: #{do_moves.(new_stack) |> get_tops.()}")
