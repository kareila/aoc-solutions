# Solution to Advent of Code 2018, Day 1
# https://adventofcode.com/2018/day/1

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

data = read_input.() |> Enum.map(&String.to_integer/1)

IO.puts("Part 1: #{Enum.sum(data)}")


find_repeat = fn nums ->
  Enum.reduce_while(Stream.cycle([1]), {0, MapSet.new([0])}, fn _, found ->
    newfound =
      Enum.reduce_while(nums, found, fn n, {tot, seen} ->
        tot = tot + n
        if MapSet.member?(seen, tot), do: {:halt, tot},
        else: {:cont, {tot, MapSet.put(seen, tot)}}
      end)
    if is_tuple(newfound), do: {:cont, newfound}, else: {:halt, newfound}
  end)
end

IO.puts("Part 2: #{find_repeat.(data)}")
