# Solution to Advent of Code 2018, Day 19
# https://adventofcode.com/2018/day/19

import Bitwise

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

all_matches = fn str, pat ->
  Regex.scan(pat, str, capture: :all_but_first) |> Enum.concat
end

read_numbers = fn str ->
  all_matches.(str, ~r/(\d+)/) |> Enum.map(&String.to_integer/1)
end

parse_lines = fn lines ->
  [ip | lines] = lines
  [ip] = read_numbers.(ip)
  lines =
    Enum.map(lines, fn line ->
      [inst, nums] = String.split(line, " ", parts: 2)
      [inst | read_numbers.(nums)]
    end)
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

run_program = fn input ->
  init = {0, 0, 0, 0, 0, 0}
  Enum.reduce_while(Stream.cycle([1]), {init, 0}, fn _, {r, ip} ->
    line = Enum.at(input.lines, ip, nil)
    if line == nil, do: {:halt, r},
    else: {:cont, exec_line.(input, r, ip, line)}
  end) |> elem(0)
end

input = read_input.() |> parse_lines.()

IO.puts("Part 1: #{run_program.(input)}")


# For Part 2, we can't naively run the program as described because
# it will loop for a long time. The exercise apparently intends for
# you to reverse engineer what your program is actually trying to do,
# which in this case is to sum all of the integers that divide evenly
# into the largest number held in the register after the register is
# fully initialized. (I didn't bother to figure this out for myself.)

find_loop = fn input ->
  init = {1, 0, 0, 0, 0, 0}
  Enum.reduce_while(Stream.cycle([1]), {init, 0}, fn _, {r, ip} ->
    line = Enum.at(input.lines, ip, nil)
    if line == nil do {:halt, r}
    else
      {r, nxtip} = exec_line.(input, r, ip, line)
      if nxtip < ip, do: {:halt, r}, else: {:cont, {r, nxtip}}
    end
  end)
end

find_sum = fn num ->
  Enum.filter(1..num, fn n -> rem(num, n) == 0 end) |> Enum.sum
end

bignum = find_loop.(input) |> Tuple.to_list |> Enum.max

IO.puts("Part 2: #{find_sum.(bignum)}")
