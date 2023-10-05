# Solution to Advent of Code 2020, Day 5
# https://adventofcode.com/2020/day/5

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

find_idx = fn code, f ->
  n = String.length(code)
  limit = Integer.pow(2, n) - 1
  Enum.reduce(1..n, Range.to_list(0..limit), fn c, i ->
    i_split = Enum.split(i, div(length(i), 2))
    elem(i_split, Map.fetch!(f, String.at(code, c - 1)))
  end) |> hd
end

find_row = fn code -> find_idx.(code, %{"F" => 0, "B" => 1}) end
find_col = fn code -> find_idx.(code, %{"L" => 0, "R" => 1}) end

seat_id = fn line ->
  {r, c} = String.split_at(line, 7)
  8 * find_row.(r) + find_col.(c)
end

seats = read_input.() |> Enum.map(seat_id) |> MapSet.new

IO.puts("Part 1: #{Enum.max(seats)}")


occ = fn id -> MapSet.member?(seats, id) end

empty_seat =
  Range.new(seat_id.("FFFFFFFLLL"), seat_id.("BBBBBBBRRR")) |>
  Enum.find(fn id -> not occ.(id) and occ.(id - 1) and occ.(id + 1) end)

IO.puts("Part 2: #{empty_seat}")
