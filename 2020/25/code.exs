# Solution to Advent of Code 2020, Day 25
# https://adventofcode.com/2020/day/25

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

init_data = fn lines ->
  keys = Enum.map(lines, &String.to_integer/1)
  %{keys: keys, modulus: 20201227, init_subject: 7}
end

data = read_input.() |> init_data.()

loop_step = fn val, subject, num_times ->
  Enum.reduce(1..num_times, val, fn _, val ->
    Integer.mod(val * subject, data.modulus)
  end)
end

loop_size = fn k ->
  Enum.reduce_while(Stream.iterate(0, &(&1 + 1)), 1, fn sz, answer ->
    if answer == k, do: {:halt, sz},
    else: {:cont, loop_step.(answer, data.init_subject, 1)}
  end)
end

encryption_key = fn [k1, k2] -> loop_step.(1, k1, loop_size.(k2)) end

IO.puts("Part 1: #{encryption_key.(data.keys)}")

# There is no Part 2!  Merry Christmas!
