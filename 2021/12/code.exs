# Solution to Advent of Code 2021, Day 12
# https://adventofcode.com/2021/day/12

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_line = fn line ->
  [_, n1, n2] = Regex.run(~r/^([^-]+)-([^-]+)$/, line)
  Enum.reduce([{n1, n2}, {n2, n1}], %{}, fn {st, en}, links ->
    if st == "end" or en == "start", do: links, # can't reverse these
    else: Map.put(links, st, [en])
  end)
end

parse_lines = fn lines ->
  Enum.reduce(lines, %{}, fn line, links ->
    Map.merge(links, parse_line.(line), fn _, v1, v2 -> v1 ++ v2 end)
  end)
end

links = read_input.() |> parse_lines.()

# In Part 2, we are allowed to visit one small (lowercase) cave twice.
init_state = %{pos: "start", small: false, visited: MapSet.new}

map_paths = fn init ->
  Enum.reduce_while(Stream.cycle([1]), {[init], 0}, fn _, {queue, found} ->
    if Enum.empty?(queue) do {:halt, found}
    else
      [%{pos: pos, visited: visited, small: small} | queue] = queue
      found = if pos == "end", do: found + 1, else: found
      {pos, small} =
        if pos == String.downcase(pos) and MapSet.member?(visited, pos),
        do: {if(small, do: pos, else: "end"), false}, else: {pos, small}
      visited = MapSet.put(visited, pos)
      new_states = Map.get(links, pos, []) |> # for end, this will be empty
        Enum.map(fn p -> %{pos: p, visited: visited, small: small} end)
      {:cont, {new_states ++ queue, found}}          
    end
  end)
end

IO.puts("Part 1: #{map_paths.(init_state)}")

# Notably, there's a huge performance difference between DFS and BFS,
# the difference being whether new_states is prepended (DFS) or appended
# (BFS) to the queue. DFS even outperforms the recursion I wrote in Perl.

IO.puts("Part 2: #{map_paths.(%{init_state | small: true})}")
