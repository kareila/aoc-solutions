# Solution to Advent of Code 2018, Day 5
# https://adventofcode.com/2018/day/5

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

data = read_input.() |> hd

react_all = fn line ->
  units = String.graphemes(line)
  Enum.reduce_while(Stream.cycle([1]), {[], units}, fn _, {a, [cur | b]} ->
    cond do
      length(b) == 0 -> {:halt, length([cur | a])}
      String.upcase(cur) == String.upcase(hd(b)) and cur != hd(b) ->
        d = if length(a) == 0, do: nil, else: hd(a)
        a = if length(a) == 0, do: a, else: tl(a)
        b = if d, do: [d | tl(b)], else: tl(b)
        {:cont, {a, b}}
      true -> {:cont, {[cur | a], b}}
    end
  end)
end

IO.puts("Part 1: #{react_all.(data)}")


poly_types = data |> String.upcase |> String.graphemes |> Enum.uniq

test_removal = fn type ->
  String.replace(data, [type, String.downcase(type)], "") |> react_all.()
end

start_task = fn input -> Task.async(fn -> test_removal.(input) end) end

await_task_result = fn task -> Task.await(task, 10000) end

trials = poly_types |> Enum.map(start_task) |> Enum.map(await_task_result)

IO.puts("Part 2: #{Enum.min(trials)}")

# elapsed time: approx. 9 sec for both parts together
