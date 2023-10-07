# Solution to Advent of Code 2021, Day 18
# https://adventofcode.com/2021/day/18

Code.require_file("Recurse.ex", ".")  # for reduce() and magnitude()

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# append a new element to the final element of a list
tail_add = fn list, item ->
  case List.last(list) do
    nil -> item  # implied base case is the final collapsed item
    tail -> List.insert_at(tail, -1, item)
         |> then(&List.replace_at(list, -1, &1))
  end
end

parse_line = fn line ->
  Enum.reduce(String.split(line, ","), [], fn element, p ->
    [_, opens, num, closes] = Regex.run(~r/^(\[*)(.*?)(\]*)$/, element)
    [opens, closes] = [String.length(opens), String.length(closes)]
    p = if opens == 0, do: p, else:
        Enum.reduce(1..opens, p, fn _, p -> List.insert_at(p, -1, []) end)
    num = if String.length(num), do: String.to_integer(num), else: nil
    p = if is_nil(num), do: p, else: tail_add.(p, num)
    if closes == 0, do: p, else:
    Enum.reduce(1..closes, p, fn _, p ->
      {tail, p} = List.pop_at(p, -1)  # close the current level...
      tail_add.(p, tail)              # ...and add it to the parent level
    end)
  end)
end

# explodes work from left to right
drill_down = fn pl, pr, stack_left, stack_right ->
  Enum.reduce_while(Stream.cycle([1]), {pl, pr, stack_left, stack_right},
  fn _, {pl, pr, stack_left, stack_right} ->
    cond do
      is_list pl ->
        stack_left = stack_left |> List.insert_at(-1, nil)
        stack_right = stack_right |> List.insert_at(-1, pr)
        [pl, pr] = pl
        {:cont, {pl, pr, stack_left, stack_right}}
      is_list pr ->
        stack_left = stack_left |> List.insert_at(-1, pl)
        stack_right = stack_right |> List.insert_at(-1, nil)
        [pl, pr] = pr
        {:cont, {pl, pr, stack_left, stack_right}}
      true -> {:halt, {pl, pr, stack_left, stack_right}}
    end
  end)
end

# do a deep replace in a list and roll back the result
branch_add = fn num, list, i ->
  Enum.reduce_while(Stream.cycle([1]), [list], fn _, find_r ->
    nxt = Enum.at(hd(find_r), i)
    if is_list(nxt), do: {:cont, [nxt | find_r]},
    else: {:halt, [nxt + num | find_r]}
  end) |> Enum.reduce(&List.replace_at(&1, i, &2))
end

# find the left and right numbers to explode to
propagate = fn dir, explode, new_p ->
  if is_nil(explode[dir]) do {new_p, explode}
  else
    ni = %{left: 0, right: 1} |> Map.fetch!(dir)
    fi = %{left: 1, right: 0} |> Map.fetch!(dir)
    pn = Enum.at(new_p, ni)
    new_n =
      if is_list(pn), do: branch_add.(explode[dir], pn, fi),
      else: pn + explode[dir]
    {List.replace_at(new_p, ni, new_n), Map.delete(explode, dir)}
  end
end

explode_stacks = fn init ->
  Enum.reduce_while(Stream.cycle([1]), init,
  fn _, {stack_left, stack_right, explode, new_p} ->
    # note: stacks have equal length, just pick one to check
    if Enum.empty?(stack_left) do {:halt, new_p}
    else
      {pl, stack_left} = stack_left |> List.pop_at(-1)
      {pr, stack_right} = stack_right |> List.pop_at(-1)
      {new_p, explode} =
        if is_nil(pl), do: propagate.(:right, explode, [new_p, pr]),
        else: propagate.(:left, explode, [pl, new_p])
      {:cont, {stack_left, stack_right, explode, new_p}}
    end
  end)
end

search_stacks_down = fn init ->
  Enum.reduce_while(Stream.cycle([1]), init,
  fn _, {stack_left, stack_right, new_p} ->
    if Enum.empty?(stack_left) do {:halt, nil}  # nothing changed
    else
      {pl, stack_left} = stack_left |> List.pop_at(-1)
      {pr, stack_right} = stack_right |> List.pop_at(-1)
      cond do
        not is_nil(pl) -> {:cont, {stack_left, stack_right, [pl, new_p]}}
        is_list(pr) ->
          stack_left = stack_left |> List.insert_at(-1, new_p)
          stack_right = stack_right |> List.insert_at(-1, nil)
          [pl, pr] = pr
          {:halt, drill_down.(pl, pr, stack_left, stack_right)}
        true -> {:cont, {stack_left, stack_right, [new_p, pr]}}
      end
    end
  end)
end

do_explodes = fn [pl, pr] ->
  Enum.reduce_while(Stream.cycle([1]), drill_down.(pl, pr, [], []),
  fn _, {pl, pr, stack_left, stack_right} ->
    cond do
      Enum.empty?(stack_right) -> {:halt, nil}  # nothing exploded
      length(stack_right) == 4 ->  # need to explode
        explode = %{left: pl, right: pr}
        {:halt, explode_stacks.({stack_left, stack_right, explode, 0})}
      true ->
        result = search_stacks_down.({stack_left, stack_right, [pl, pr]})
        if is_nil(result), do: {:halt, nil}, else: {:cont, result}
    end
  end)
end

# splits work from left to right
next_left = fn pl, pr, stack_left, stack_right ->
  Enum.reduce_while(Stream.cycle([1]), {pl, pr, stack_left, stack_right},
  fn _, {pl, pr, stack_left, stack_right} ->
    if is_list pl do
      stack_left = stack_left |> List.insert_at(-1, nil)
      stack_right = stack_right |> List.insert_at(-1, pr)
      [pl, pr] = pl
      {:cont, {pl, pr, stack_left, stack_right}}
    else
      {:halt, {pl, pr, stack_left, stack_right}}
    end
  end)
end

split_val = fn num ->
  half = div(num, 2)
  [half, num - half]
end

split_stacks = fn init ->
  Enum.reduce_while(Stream.cycle([1]), init,
  fn _, {stack_left, stack_right, new_p} ->
    # note: stacks have equal length, just pick one to check
    if Enum.empty?(stack_left) do {:halt, new_p}
    else
      {pl, stack_left} = stack_left |> List.pop_at(-1)
      {pr, stack_right} = stack_right |> List.pop_at(-1)
      if is_nil(pl), do: {:cont, {stack_left, stack_right, [new_p, pr]}},
      else: {:cont, {stack_left, stack_right, [pl, new_p]}}
    end
  end)
end

search_stacks_left = fn init ->
  Enum.reduce_while(Stream.cycle([1]), init,
  fn _, {stack_left, stack_right, new_p} ->
    if Enum.empty?(stack_left) do {:halt, nil}  # nothing changed
    else
      {pl, stack_left} = stack_left |> List.pop_at(-1)
      {pr, stack_right} = stack_right |> List.pop_at(-1)
      cond do
        not is_nil(pl) -> {:cont, {stack_left, stack_right, [pl, new_p]}}
        is_list(pr) ->
          stack_left = stack_left |> List.insert_at(-1, new_p)
          stack_right = stack_right |> List.insert_at(-1, nil)
          [pl, pr] = pr
          {:halt, next_left.(pl, pr, stack_left, stack_right)}
        pr > 9 -> {:halt, {new_p, pr, stack_left, stack_right}}
        true -> {:cont, {stack_left, stack_right, [new_p, pr]}}
      end
    end
  end)
end

# split values can be at the top level
do_splits = fn [pl, pr] ->
  Enum.reduce_while(Stream.cycle([1]), next_left.(pl, pr, [], []),
  fn _, {pl, pr, stack_left, stack_right} ->
    cond do
      is_integer(pl) and pl > 9 ->
        new_p = [split_val.(pl), pr]
        {:halt, split_stacks.({stack_left, stack_right, new_p})}
      is_integer(pr) and pr > 9 ->
        new_p = [pl, split_val.(pr)]
        {:halt, split_stacks.({stack_left, stack_right, new_p})}
      is_list(pr) ->
        stack_left = stack_left |> List.insert_at(-1, pl)
        stack_right = stack_right |> List.insert_at(-1, nil)
        [pl, pr] = pr
        {:cont, next_left.(pl, pr, stack_left, stack_right)}
      true ->
        result = search_stacks_left.({stack_left, stack_right, [pl, pr]})
        if is_nil(result), do: {:halt, nil}, else: {:cont, result}
    end
  end)
end

reduce_pair = fn p -> Recurse.reduce(p, do_explodes, do_splits) end

pairs = read_input.() |> Enum.map(parse_line)

calc_list = fn ->
  Enum.reduce(pairs, fn pr, pl -> reduce_pair.([pl, pr]) end)
end

IO.puts("Part 1: #{calc_list.() |> Recurse.magnitude}")


start_task = fn idx ->
  pair = Enum.map(idx, &Enum.at(pairs, &1))
  Task.async(fn -> reduce_pair.(pair) |> Recurse.magnitude end)
end

# check all x+y and y+x and note the max magnitude
calc_pairs = fn ->
  limit = length(pairs) - 1
  for i <- 0..limit, j <- 0..limit, i != j do [i, j] end |>
  Enum.map(start_task) |> Enum.map(&Task.await/1) |> Enum.max
end

IO.puts("Part 2: #{calc_pairs.()}")

# elapsed time: approx. 0.8 sec for both parts together
# (best Perl version was 10 seconds... yay async)
