# Solution to Advent of Code 2017, Day 9
# https://adventofcode.com/2017/day/9

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# reminder that manipulating large linked lists is painful (see day 5)
list_to_map = fn list ->
  Enum.with_index(list) |> Map.new(fn {v, i} -> {i, v} end)
end

remove_garbage = fn data ->
  result =
    Enum.reduce(Enum.sort(data), {%{}, nil, false, []},
    fn {i, c}, {output, cancel, in_garbage?, trash} ->
      if not in_garbage? do
        if c == "<", do: {output, nil, true, trash},
        else: {Map.put(output, map_size(output), c), nil, false, trash}
      else  # inside garbage
        cond do
          i == cancel -> {output, nil, true, trash}
          c == "!" -> {output, i + 1, true, trash}
          c == ">" -> {output, nil, false, trash}
          true -> {output, nil, true, [c | trash]}
        end
      end
    end)
  %{groups: elem(result, 0), trash: elem(result, 3)}
end

score = fn data ->
  Enum.reduce(Enum.sort(data), {0, 0}, fn {_, c}, {stack, score} ->
    cond do
      c == "}" and stack == 0 -> raise(RuntimeError)
      c == "}" -> {stack - 1, score + stack}
      c == "{" -> {stack + 1, score}
      true -> {stack, score}
    end
  end) |> elem(1)
end

data = read_input.() |> hd |> String.graphemes |>
       list_to_map.() |> remove_garbage.()

IO.puts("Part 1: #{score.(data.groups)}")
IO.puts("Part 2: #{length(data.trash)}")
