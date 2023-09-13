# Solution to Advent of Code 2018, Day 2
# https://adventofcode.com/2018/day/2

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

line_stat = fn line ->
  String.graphemes(line) |> Enum.frequencies |> Map.values
end

checksum = fn lines ->
  vals = Enum.map(lines, line_stat)
  twos = Enum.count(vals, fn v -> 2 in v end)
  threes = Enum.count(vals, fn v -> 3 in v end)
  twos * threes
end

IO.puts("Part 1: #{read_input.() |> checksum.()}")


# This uses String.bag_distance to quickly find similar candidates,
# but mirrored transpositions count as sameness, so it's not a complete
# solution. Specifically, with my data set, this finds two candidates
# with three differences as well as the one with only one difference.

same_letters = fn {line1, line2} ->
  Enum.map([line1, line2], &String.graphemes/1) |>
  Enum.zip_reduce("", fn [c1, c2], ret ->
    if c1 == c2, do: ret <> c1, else: ret
  end)
end

id_length = read_input.() |> hd |> String.length
target_distance = (id_length - 1) / id_length

find_boxes = fn lines ->
  Enum.reduce(lines, {[], []}, fn line, {seen, found} ->
    Enum.reduce(seen, {line, found}, fn line1, {line2, found} ->
      if String.bag_distance(line1, line2) == target_distance,
      do: {line2, [{line1, line2} | found]}, else: {line2, found}
    end) |> put_elem(0, [line | seen])
  end) |> elem(1) |> Enum.map(same_letters) |> Enum.max_by(&String.length/1)
end

IO.puts("Part 2: #{read_input.() |> find_boxes.()}")
