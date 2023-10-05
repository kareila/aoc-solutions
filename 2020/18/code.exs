# Solution to Advent of Code 2020, Day 18
# https://adventofcode.com/2020/day/18

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

lines = read_input.() |> Enum.map(&String.split/1)

list_to_int = fn list -> Enum.join(list) |> String.to_integer end

calculate = fn [s1, op, s2] ->
  {open, n1} = String.graphemes(s1) |> Enum.split_with(&(&1 == "("))
  {shut, n2} = String.graphemes(s2) |> Enum.split_with(&(&1 == ")"))
  [n1, n2] = [list_to_int.(n1), list_to_int.(n2)]
  [p1, p2] = [Enum.join(open), Enum.join(shut)]
  case op do
    "+" -> "#{p1}#{n1 + n2}#{p2}"
    "*" -> "#{p1}#{n1 * n2}#{p2}"
    op -> raise RuntimeError, "Unknown operator: #{op}"
  end
end

calc_next = fn exp, stack, check_op ->
  {[s1, op, s2] = nxt, exp} = Enum.split(exp, 3)
  cond do
    String.starts_with?(s2, "(") -> {[s2 | exp], stack ++ [s1, op]}
    String.starts_with?(s1, "(") and String.ends_with?(s2, ")") ->
      {stack ++ [calculate.(nxt) |> String.slice(1..-2//1) | exp], []}
    check_op.(op, exp) -> {[s2 | exp], stack ++ [s1, op]}
    String.starts_with?(s1, "(") -> {[calculate.(nxt) | exp], stack}
    true -> {stack ++ [calculate.(nxt) | exp], []}
  end
end

eval_exp = fn line, check_op ->
  Enum.reduce_while(Stream.cycle([1]), {line, []}, fn _, {exp, stack} ->
    cond do
      length(exp) == 1 and Enum.empty?(stack) -> {:halt, hd(exp)}
      length(exp) == 1 -> {:cont, {stack ++ exp, []}}
      true -> {:cont, calc_next.(exp, stack, check_op)}
    end
  end)
end

no_op = fn _, _ -> false end

eval_all = fn check_op ->
  Enum.map(lines, &eval_exp.(&1, check_op)) |>
  Enum.map(&String.to_integer/1) |> Enum.sum
end

IO.puts("Part 1: #{eval_all.(no_op)}")


# now do all additions before multiplications
# return true if we need to stack this for now
check_op = fn op, exp ->
  par = Enum.find_index(exp, &String.ends_with?(&1, ")"))
  add = Enum.find_index(exp, &(&1 == "+"))
  cond do
    op == "+" -> false
    not Enum.member?(exp, "+") -> false
    is_nil(par) -> true
    par < add -> false
    true -> true
  end
end

IO.puts("Part 2: #{eval_all.(check_op)}")
