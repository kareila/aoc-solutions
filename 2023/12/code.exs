# Solution to Advent of Code 2023, Day 12
# https://adventofcode.com/2023/day/12

Code.require_file("Util.ex", "..")
Code.require_file("Recurse.ex", ".")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_line = fn line ->
  [pat, chk] = String.split(line)
  %{pat: pat, chk: Util.read_numbers(chk)}
end

data = read_input.() |> Enum.map(parse_line)

# A regular expression filter works for Part 1 but is slow.
# For Part 2, the exponential growth of the number of strings
# to examine makes filtering the full list of possibilities
# intractable. So this solution uses memoized recursion.

p_count = fn %{pat: pat, chk: chk} ->
  Recurse.p_count(String.graphemes(pat), chk) |> elem(0)
end

IO.puts("Part 1: #{Enum.map(data, p_count) |> Enum.sum}")


unfold_line = fn %{pat: pat, chk: chk} ->
  chk = List.duplicate(chk, 5) |> List.flatten
  pat = List.duplicate([pat], 5) |> Enum.join("?")
  %{pat: pat, chk: chk}
end

# run each line's count in its own thread to speed things up
start_task = fn data -> Task.async(fn -> p_count.(data) end) end
unfold_counts = Enum.map(data, unfold_line) |> Enum.map(start_task)

IO.puts("Part 2: #{Enum.map(unfold_counts, &Task.await/1) |> Enum.sum}")

# elapsed time: approx. 1.5 sec for both parts together
