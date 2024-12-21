# Solution to Advent of Code 2024, Day 17
# https://adventofcode.com/2024/day/17

Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_input = fn list ->
  [[a], [b], [c], p] = Enum.map(list, &Util.read_numbers/1)
  %{a: a, b: b, c: c, p: p, i: 0, output: []}
end

program = read_input.() |> parse_input.()


get_combo = fn n, %{a: a, b: b, c: c} ->
  %{0 => 0, 1 => 1, 2 => 2, 3 => 3, 4 => a, 5 => b, 6 => c} |> Map.fetch!(n)
end

parse_op = fn [c, n], data ->
  ncombo = get_combo.(n, data)
  case c do
    0 -> %{data | a: data.a |> div(2 ** ncombo)}
    1 -> %{data | b: data.b |> Bitwise.bxor(n)}
    2 -> %{data | b: ncombo |> Integer.mod(8)}
    3 -> if data.a == 0, do: data, else: %{data | i: n - 2}
    4 -> %{data | b: data.b |> Bitwise.bxor(data.c)}
    5 -> %{data | output: [ncombo |> Integer.mod(8) | data.output]}
    6 -> %{data | b: data.a |> div(2 ** ncombo)}
    7 -> %{data | c: data.a |> div(2 ** ncombo)}
  end
end

next_i = fn data ->
  nxt = Enum.drop(data.p, data.i) |> Enum.take(2)
  if Enum.empty?(nxt) do nil
  else
    data = parse_op.(nxt, data)
    %{data | i: data.i + 2}
  end
end

run_program = fn p ->
  Enum.reduce_while(Stream.cycle([1]), p, fn _, data ->
    nxt = next_i.(data)
    if not is_nil(nxt), do: {:cont, nxt},
    else: {:halt, Enum.reverse(data.output)}
  end)
end

IO.puts("Part 1: #{run_program.(program) |> Enum.join(",")}")

not_equiv = fn a, i, data ->
  run_program.(%{data | a: a}) != Enum.take(data.p, i)
end

solve_digit = fn n, i, data ->
  Stream.iterate(0, & &1 + 1) |>
  Stream.drop_while(&not_equiv.(&1 + n, i, data)) |>
  Stream.take(1) |> Enum.to_list |> hd |> then(& &1 + n)
end

solve_output = fn data ->
  sz = length(data.p)
  Enum.reduce(1..sz, 0, fn i, n -> solve_digit.(8 * n, -i, data) end)
end

IO.puts("Part 2: #{solve_output.(program)}")
