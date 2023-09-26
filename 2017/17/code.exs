# Solution to Advent of Code 2017, Day 17
# https://adventofcode.com/2017/day/17

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

step = read_input.() |> hd |> String.to_integer

next_position = fn pos, len -> Integer.mod(pos + step, len) + 1 end

spinlock =
  Enum.reduce(1..2017, {0, [0]}, fn v, {pos, buffer} ->
    index = next_position.(pos, length(buffer))
    {index, List.insert_at(buffer, index, v)}
  end) |> elem(1)

loc_2017 = Enum.find_index(spinlock, &(&1 == 2017))

IO.puts("Part 1: #{Enum.at(spinlock, loc_2017 + 1)}")


# A 50 million element linked list isn't going to be manageable... but
# we don't need to track the whole list if we're looking for the number
# after 0, because that will always be at index 0. We just need to find
# the last value that would have been inserted at position 1.
find_one = fn n ->
  Enum.reduce(1..n, {0, nil}, fn len, {pos, one} ->
    index = next_position.(pos, len)
    {index, if(index == 1, do: len, else: one)}
  end) |> elem(1)
end

IO.puts("Part 2: #{find_one.(50_000_000)}")
