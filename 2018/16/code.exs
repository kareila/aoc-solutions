# Solution to Advent of Code 2018, Day 16
# https://adventofcode.com/2018/day/16

import Bitwise

Code.require_file("Util.ex", "..")

parse_block = fn str ->
  String.split(str, "\n", trim: true) |> Enum.map(&Util.read_numbers/1)
end

parse_sample = fn str ->
  Enum.zip([:before, :instruction, :after], parse_block.(str)) |> Map.new
end

parse_input = fn ->
  [samples, program] = "input.txt" |> File.read! |> String.split("\n\n\n\n")
  samples = String.split(samples, "\n\n") |> Enum.map(parse_sample)
  %{samples: samples, program: parse_block.(program)}
end

# Now we program the 16 possible operations?
# Instructions are lists, registers are tuples.
op_addr = fn [_, a, b, c], r ->
  put_elem(r, c, elem(r, a) + elem(r, b)) end

op_addi = fn [_, a, b, c], r ->
  put_elem(r, c, elem(r, a) + b) end

op_mulr = fn [_, a, b, c], r ->
  put_elem(r, c, elem(r, a) * elem(r, b)) end

op_muli = fn [_, a, b, c], r ->
  put_elem(r, c, elem(r, a) * b) end

op_banr = fn [_, a, b, c], r ->
  put_elem(r, c, elem(r, a) &&& elem(r, b)) end

op_bani = fn [_, a, b, c], r ->
  put_elem(r, c, elem(r, a) &&& b) end

op_borr = fn [_, a, b, c], r ->
  put_elem(r, c, elem(r, a) ||| elem(r, b)) end

op_bori = fn [_, a, b, c], r ->
  put_elem(r, c, elem(r, a) ||| b) end

op_setr = fn [_, a, _, c], r ->
  put_elem(r, c, elem(r, a)) end

op_seti = fn [_, a, _, c], r ->
  put_elem(r, c, a) end

op_gtir = fn [_, a, b, c], r ->
  put_elem(r, c, if(a > elem(r, b), do: 1, else: 0)) end

op_gtri = fn [_, a, b, c], r ->
  put_elem(r, c, if(elem(r, a) > b, do: 1, else: 0)) end

op_gtrr = fn [_, a, b, c], r ->
  put_elem(r, c, if(elem(r, a) > elem(r, b), do: 1, else: 0)) end

op_eqir = fn [_, a, b, c], r ->
  put_elem(r, c, if(a == elem(r, b), do: 1, else: 0)) end

op_eqri = fn [_, a, b, c], r ->
  put_elem(r, c, if(elem(r, a) == b, do: 1, else: 0)) end

op_eqrr = fn [_, a, b, c], r ->
  put_elem(r, c, if(elem(r, a) == elem(r, b), do: 1, else: 0)) end

operations = [
  op_addr, op_addi, op_mulr, op_muli, op_banr, op_bani, op_borr, op_bori,
  op_setr, op_seti, op_gtir, op_gtri, op_gtrr, op_eqir, op_eqri, op_eqrr
]

op_result = fn s ->
  Enum.map(operations, fn op ->
    op.(s.instruction, List.to_tuple(s.before)) |> Tuple.to_list
  end)
end

test_sample = fn s -> op_result.(s) |> Enum.count(&(&1 == s.after)) end

test_all = fn input ->
  Enum.map(input.samples, test_sample) |> Enum.count(fn n -> n > 2 end)
end

IO.puts("Part 1: #{test_all.(parse_input.())}")


# Now, of course, we're supposed to figure out which opcode is which.
# We can list the (thankfully) one-to-one correlation between each opcode
# and the indices of the functions in my operations list that calculate
# the correct result for its sample. Then we can iteratively reduce the
# remaining possibilities to find the unique solution.

matching_ops = fn samples, omit ->
  Enum.map(samples, fn s ->
    op_result.(s) |> Util.list_to_map |> Enum.flat_map(fn {i, v} ->
      if v == s.after and {i} not in omit, do: [i], else: []
    end) |> List.to_tuple |> then(&Map.put(s, :opts, &1))
  end) |> Enum.reject(&(tuple_size(&1.opts) == 0)) |>
  Map.new(fn s -> {hd(s.instruction), s.opts} end)
end

create_op_map = fn samples ->
  Enum.reduce_while(Stream.cycle([1]), %{}, fn _, opcodes ->
    {choice, matches} =
      matching_ops.(samples, Map.values(opcodes)) |>
      Enum.split_with(&(tuple_size(elem(&1,1)) == 1))
    if Enum.empty?(choice), do: raise(RuntimeError)
    opcodes = Map.merge(opcodes, Map.new(choice))
    if Enum.empty?(matches), do: {:halt, opcodes}, else: {:cont, opcodes}
  end)
end

op_fns = fn input ->
  create_op_map.(input.samples) |> 
  Map.new(fn {opc, {i}} -> {opc, Enum.at(operations, i)} end)
end

run_program = fn input ->
  ops = op_fns.(input)
  Enum.reduce(input.program, {0, 0, 0, 0}, fn step, r ->
    Map.fetch!(ops, hd(step)).(step, r)
  end) |> elem(0)
end

IO.puts("Part 2: #{run_program.(parse_input.())}")
