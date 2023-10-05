# Solution to Advent of Code 2020, Day 6
# https://adventofcode.com/2020/day/6

# returns a list of non-blank BLOCKS from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n\n", trim: true)
end

parse_block = fn block ->
  answers = String.split(block, "\n", trim: true) |>
            Enum.map(fn line -> String.graphemes(line) |> Enum.uniq end)
  letters = List.flatten(answers) |> MapSet.new
  %{all: letters, group: answers}
end

data = read_input.() |> Enum.map(parse_block)

pt1 = Enum.map(data, &MapSet.size(&1.all))

IO.puts("Part 1: #{Enum.sum(pt1)}")


group_all = fn g ->
  Enum.count(g.all, fn c -> Enum.all?(g.group, &(c in &1)) end)
end

pt2 = Enum.map(data, group_all)

IO.puts("Part 2: #{Enum.sum(pt2)}")
