# Solution to Advent of Code 2018, Day 21
# https://adventofcode.com/2018/day/21

# this is largely copied from day 19

import Bitwise

Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_lines = fn lines ->
  [ip | lines] = lines
  [ip] = Util.read_numbers(ip)
  lines =
    Enum.map(lines, fn line ->
      [inst, nums] = String.split(line, " ", parts: 2)
      [inst | Util.read_numbers(nums)]
    end) |> Util.list_to_map
  %{ip: ip, lines: lines}
end

# Reuse the 16 possible operations from Day 16.
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

operations = %{
  "addr" => op_addr, "addi" => op_addi, "mulr" => op_mulr, "muli" => op_muli,
  "banr" => op_banr, "bani" => op_bani, "borr" => op_borr, "bori" => op_bori,
  "setr" => op_setr, "seti" => op_seti, "gtir" => op_gtir, "gtri" => op_gtri,
  "gtrr" => op_gtrr, "eqir" => op_eqir, "eqri" => op_eqri, "eqrr" => op_eqrr,
}

op_result = fn register, line ->
  Map.fetch!(operations, hd(line)).(line, register)
end

exec_line = fn input, r, ip, line ->
  # write the instruction pointer's value to its register before execution
  r = put_elem(r, input.ip, ip) |> op_result.(line)
  # update and then increment the instruction pointer
  {r, elem(r, input.ip) + 1}
end

# I have no patience for "deconstruct my assembly language" puzzles,
# so I once again immediately looked for an explanation elsewhere.
# What I found: the only time register 0 is being used is in the
# input line that contains an instruction starting with `eqrr 3 0`.
# So we can check the contents of register 3 whenever ip is the
# line number containing that instruction. The answer for Part 1 is
# the first value seen, and the answer for Part 2 is the last value
# seen before a repeated register state is detected.
#
# I am passing the target register as a parameter since I doubt
# every potential input uses the exact same comparison. I could
# parse it from the line data, but it doesn't seem worth the effort
# when the point of this exercise is to make algorithmic deductions
# based on inspecting the values of the input data.

find_reg = fn input, q ->
  init = {0, 0, 0, 0, 0, 0}
  lnno = Enum.flat_map(input.lines, fn {i, [op | _]} ->
         if op == "eqrr", do: [i], else: [] end) |> hd
  Enum.reduce_while(Stream.cycle([1]), {init, 0}, fn _, {r, ip} ->
    line = Map.get(input.lines, ip)
    if is_nil(line) do {:halt, r}
    else
      {r, nxtip} = exec_line.(input, r, ip, line)
      if nxtip == lnno, do: {:halt, elem(r, q)},
      else: {:cont, {r, nxtip}}
    end
  end)
end

input = read_input.() |> parse_lines.()

IO.puts("Part 1: #{find_reg.(input, 3)}")


# Note: Part 2 takes a rather long time to run - presumably a
# fully reverse engineered replacement algorithm similar to
# Part 2 of Day 19 would be much faster, but I can't be bothered.

cycle_reg = fn input, q ->
  init = {0, 0, 0, 0, 0, 0}
  lnno = Enum.flat_map(input.lines, fn {i, [op | _]} ->
         if op == "eqrr", do: [i], else: [] end) |> hd
  Enum.reduce_while(Stream.cycle([1]), {init, 0, MapSet.new, nil},
  fn _, {r, ip, s, e} ->
    line = Map.get(input.lines, ip)
    if is_nil(line) do {:halt, r}
    else
      {r, nxtip} = exec_line.(input, r, ip, line)
      if nxtip != lnno do {:cont, {r, nxtip, s, e}}
      else
        new_e = elem(r, q)
        if MapSet.member?(s, new_e), do: {:halt, e},
        else: {:cont, {r, nxtip, MapSet.put(s, new_e), new_e}}
      end
    end
  end)
end

IO.puts("Part 2: #{cycle_reg.(input, 3)}")

# elapsed time: approx. 5.2 minutes(!) for both parts together
# (reduced from 6.5 minutes using list_to_map)
