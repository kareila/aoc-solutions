# Solution to Advent of Code 2022, Day 13
# https://adventofcode.com/2022/day/13

Code.require_file("Util.ex", "..")
Code.require_file("Recurse.ex", ".")  # for check_pair()

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

list_to_int = fn list -> Enum.join(list) |> String.to_integer end

# append a new element to the final element of a list
tail_add = fn list, item ->
  case List.last(list) do
    nil -> item  # implied base case is the final collapsed item
    tail -> List.insert_at(tail, -1, item)
         |> then(&List.replace_at(list, -1, &1))
  end
end

parse_line = fn str ->
  Enum.reduce(String.split(str, ","), [], fn e, p ->
    chars = String.graphemes(e)
    # add a new empty list for every open bracket
    {open, chars} = Enum.split_while(chars, &(&1 == "["))
    p = p ++ List.duplicate([], length(open))
    # look for any numeric (non-bracket) characters
    {n, chars} = Enum.split_while(chars, &(&1 != "]"))
    p = if(length(n) == 0, do: p, else: tail_add.(p, list_to_int.(n)))
    # anything left must be closing brackets
    Enum.reduce(1..length(chars)//1, p, fn _, p ->
      {tail, p} = List.pop_at(p, -1)  # close the current level...
      tail_add.(p, tail)              # ...and add it to the parent level
    end)
  end)
end

all = read_input.() |> Enum.map(parse_line)

# produces list with matched pairs in tuples
pairs = fn lines ->
  Enum.chunk_every(lines, 2) |> Enum.map(&List.to_tuple/1)
end

result = pairs.(all) |>
  Enum.map(&Recurse.check_pair/1) |> Enum.with_index(1) |>
  Util.group_tuples(0, 1) |> Map.get(true, []) |> Enum.sum

IO.puts("Part 1: #{result}")


dividers = [ parse_line.("[[2]]"), parse_line.("[[6]]") ]

# Take every data element and test it against every element of
# the sorted list. When the test passes, it is in the right place.

find_pos = fn e, sorted, bool -> Enum.find_index(sorted, fn x ->
  Recurse.check_pair({e, x}) == bool end) end

sorted = Enum.reduce(all, dividers, fn line, sorted ->
  pos = find_pos.(line, sorted, true)
  List.insert_at(sorted, if(pos == nil, do: -1, else: pos), line)
end)

# Now search the sorted list for the locations of the divider packets.
idx_div = Enum.map(dividers, fn d -> 1 + find_pos.(d, sorted, nil) end)

IO.puts("Part 2: #{Enum.product(idx_div)}")
