# Solution to Advent of Code 2022, Day 21
# https://adventofcode.com/2022/day/21

require Recurse  # for calc() and search()

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_lines = fn lines ->
  math = %{"+" => &+/2, "-" => &-/2, "*" => &*/2, "/" => &div/2}
  Enum.reduce(lines, %{}, fn l, monkeys ->
    [_, name, job] = Regex.run(~r"^([^:]+): (.*)$", l)
    if String.match?(job, ~r/^\d+$/) do
      Map.put(monkeys, name, %{num: String.to_integer(job)})
    else
      [_, a, op, b] = Regex.run(~r"^(\S+) ([-+*/]) (\S+)$", job)
      op_fn = math[op]  # also need symbol for Part 2
      Map.put(monkeys, name, %{a: a, b: b, op: op_fn, sym: op})
    end
  end)
end

monkeys = read_input.() |> parse_lines.()
root = "root"

IO.puts("Part 1: #{Recurse.calc(root, monkeys)}")


# New test: root's monkey 'a' answer and monkey 'b' answer must match;
# you must provide the correct answer for 'humn' to make that happen.
# First order of business: where in the "tree" is humn? Under root's a, or b?

humn_branch = Recurse.search([root], "humn", monkeys) |> Enum.reverse

get_other_answer = fn nxt, monkey ->
  monkey[if(nxt == monkey.a, do: :b, else: :a)] |> Recurse.calc(monkeys)
end

# Unravel the calculations down the branch, starting with root.
answer = Enum.map(humn_branch, &Map.fetch!(monkeys, &1)) |>
  Enum.zip(humn_branch |> tl) |>
  Enum.reduce(nil, fn {m, nxt}, answer ->
    a = get_other_answer.(nxt, m)
    cond do
      answer == nil -> a
      # add and multiply are easy, they don't care about a/b ordering
      m.sym == "*" -> div(answer, a)
      m.sym == "+" -> answer - a
      nxt == m.a ->
       if m.sym == "-", do: a + answer, else: a * answer
      nxt == m.b ->
       if m.sym == "-", do: a - answer, else: div(a, answer)
      true -> raise RuntimeError, "Could not traverse branch"
    end
  end)

IO.puts("Part 2: #{answer}")
