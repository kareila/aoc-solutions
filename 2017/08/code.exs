# Solution to Advent of Code 2017, Day 8
# https://adventofcode.com/2017/day/8

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_cmp = fn s ->
  %{">" => &>/2, ">=" => &>=/2, "==" => &==/2,
    "<" => &</2, "<=" => &<=/2, "!=" => &!=/2} |>
  Map.fetch!(s)
end

parse_line = fn line ->
  [r_mod, op, amt, "if", r_chk, op_chk, n_chk] = String.split(line)
  op = Map.fetch!(%{"inc" => &+/2, "dec" => &-/2}, op)
  amt = op.(0, String.to_integer(amt))
  [op_chk, n_chk] = [parse_cmp.(op_chk), String.to_integer(n_chk)]
  chk_fn = fn x -> op_chk.(x, n_chk) end
  %{r_mod: r_mod, amt: amt, r_chk: r_chk, chk_fn: chk_fn}
end

map_max = fn data -> Enum.max(Map.values(data)) end

exec_program = fn instructions ->
  Enum.reduce(instructions, {Map.new, MapSet.new},
  fn %{r_mod: r_mod, amt: amt} = info, {values, maxes} ->
    r_chk = Map.get(values, info.r_chk, 0)
    values =
      if not info.chk_fn.(r_chk), do: values,
      else: Map.update(values, r_mod, amt, &(&1 + amt))
    maxes =
      if Enum.empty?(values), do: maxes,
      else: MapSet.put(maxes, map_max.(values))
    {values, maxes}
  end)
end

{calc1, calc2} = read_input.() |> Enum.map(parse_line) |> exec_program.()

IO.puts("Part 1: #{map_max.(calc1)}")
IO.puts("Part 2: #{Enum.max(calc2)}")
