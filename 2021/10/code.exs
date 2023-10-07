# Solution to Advent of Code 2021, Day 10
# https://adventofcode.com/2021/day/10

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# just split this into characters
parse_input = fn lines -> Enum.map(lines, &String.graphemes/1) end

# adding a bogus 0 index character "_" to adjust the scores for Part 2
start_chars = "_([{<" |> String.graphemes
close_chars = "_)]}>" |> String.graphemes
error_score = %{")" => 3, "]" => 57, "}" => 1197, ">" => 25137}

# this returns the incomplete stack or an error score
evaluate_line = fn chars ->
  Enum.reduce_while(chars, [], fn c, stack ->
    find_c = fn list -> Enum.find_index(list, &(&1 == c)) end
    val = find_c.(close_chars)
    cond do
      is_nil(val) -> {:cont, [find_c.(start_chars) | stack]}
      Enum.empty?(stack) -> {:halt, Map.fetch!(error_score, c)}
      val != hd(stack) -> {:halt, Map.fetch!(error_score, c)}
      true -> {:cont, tl(stack)}
    end
  end)
end

eval_all_lines = fn lines ->
  Enum.reduce(lines, {[], 0}, fn line, {keep, score} ->
    res = evaluate_line.(line)
    if is_list(res), do: {[res | keep], score},
    else: {keep, score + res}
  end)
end

{incomplete, total_score} =
  read_input.() |> parse_input.() |> eval_all_lines.()

IO.puts("Part 1: #{total_score}")


score_line = fn line ->
  Enum.reduce(line, 0, fn v, score -> score * 5 + v end)
end

middle_score = fn ->
  all_scores = Enum.map(incomplete, score_line) |> Enum.sort
  Enum.at(all_scores, div(length(all_scores), 2))
end

IO.puts("Part 2: #{middle_score.()}")
