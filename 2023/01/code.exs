# Solution to Advent of Code 2023, Day 1
# https://adventofcode.com/2023/day/1

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# constants for parsing numbers from lines
s_nums = ~w(1 2 3 4 5 6 7 8 9)s
s_word = ~w(one two three four five six seven eight nine)s
s_both = Enum.concat(s_nums, s_word)
wn_map = Enum.zip(s_word, s_nums) |> Map.new

# list all substring matches sorted by starting index
# can't use branching regex - won't detect overlapping matches
line_matches = fn line, strs ->
  Enum.flat_map(strs, fn s ->
    m = Regex.compile!(s) |> Regex.scan(line, return: :index)
    if Enum.empty?(m), do: [], else: Enum.map(m, &{elem(hd(&1), 0), s})
  end) |> List.keysort(0) |> Enum.map(&elem(&1,1))
       |> Enum.map(&Map.get(wn_map, &1, &1))  # word -> digit
end

# take the first and last digit and convert to integer
num_from_matches = fn digits ->
  [List.first(digits), List.last(digits)] |> Enum.join |> String.to_integer
end

parse_lines = fn strs ->
  read_input.() |> Enum.map(&line_matches.(&1, strs)) |>
  Enum.map(num_from_matches) |> Enum.sum
end

IO.puts("Part 1: #{parse_lines.(s_nums)}")
IO.puts("Part 2: #{parse_lines.(s_both)}")


# Another approach I saw mentioned was to add a pre-processing step
# in Part 2 to convert e.g. seven -> s7n, eight -> e8t, etc. since
# the overlap between words is never more than one letter, and then
# rerun the simple digit search used for Part 1.  But this solution
# can be adapted to work with any set of overlapping substrings.
