# Solution to Advent of Code 2024, Day 19
# https://adventofcode.com/2024/day/19

Code.require_file("Recurse.ex", ".")

# returns TWO lists of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n\n") |>
  Enum.map(&String.split(&1, "\n", trim: true))
end

parse_input = fn [[pat], designs] ->
  %{patterns: String.split(pat, ", "), designs: designs}
end

construct_all = fn %{patterns: patterns, designs: designs} ->
  construct = fn d, cache -> Recurse.construct(d, patterns, cache) end
  Enum.flat_map_reduce(designs, %{}, construct) |> elem(0)
end

results = read_input.() |> parse_input.() |> construct_all.()

IO.puts("Part 1: #{length(results)}")
IO.puts("Part 2: #{Enum.sum(results)}")
