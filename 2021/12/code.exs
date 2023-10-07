# Solution to Advent of Code 2021, Day 12
# https://adventofcode.com/2021/day/12

Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_line = fn line ->
  [_, n1, n2] = Regex.run(~r/^([^-]+)-([^-]+)$/, line)
  Enum.flat_map([{n1, n2}, {n2, n1}], fn {st, en} ->
    if st == "end" or en == "start", do: [], else: [{st, en}]
  end)
end

parse_lines = fn lines ->
  Enum.flat_map(lines, parse_line) |> Util.group_tuples(0, 1)
end

links = read_input.() |> parse_lines.()

# In Part 2, we are allowed to visit one small (lowercase) cave twice.
init_state = %{pos: "start", small: false, visited: []}

check_pos = fn %{pos: pos, small: small, visited: visited} ->
  ended = if pos == "end", do: 1, else: 0
  {pos, small} =
    if pos == String.downcase(pos) and pos in visited,
    do: {if(small, do: pos, else: "end"), false}, else: {pos, small}
  {ended, %{pos: pos, small: small, visited: [pos | visited]}}
end

map_paths = fn init ->
  Enum.reduce_while(Stream.cycle([1]), {[init], 0}, fn _, {queue, found} ->
    if Enum.empty?(queue) do {:halt, found}
    else
      [state | queue] = queue
      {ended, state} = check_pos.(state)
      new_states = Map.get(links, state.pos, []) |>  # "end" has no links
        Enum.map(fn p -> %{state | pos: p} end)
      {:cont, {new_states ++ queue, found + ended}}
    end
  end)
end

IO.puts("Part 1: #{map_paths.(init_state)}")

# Notably, there's a huge performance difference between DFS and BFS,
# the difference being whether new_states is prepended (DFS) or appended
# (BFS) to the queue. DFS even outperforms the recursion I wrote in Perl.

IO.puts("Part 2: #{map_paths.(%{init_state | small: true})}")
