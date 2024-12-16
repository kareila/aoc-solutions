# Solution to Advent of Code 2024, Day 13
# https://adventofcode.com/2024/day/13

Code.require_file("Util.ex", "..")

# returns a LIST OF LISTS of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n\n") |>
  Enum.map(&String.split(&1, "\n", trim: true))
end

parse_machine = fn list ->
  [a, b, prize] = Enum.map(list, &List.to_tuple(Util.read_numbers(&1)))
  %{a: a, b: b, prize: prize}
end

data = read_input.() |> Enum.map(parse_machine)

# Equations to be solved:
# 1. p * x_a + q * x_b = x_z
# 2. p * y_a + q * y_b = y_z
#
# Rearrange 1: p = (x_z - q * x_b) / x_a
# Plug into 2: (x_z - q * x_b) / x_a * y_a + q * y_b = y_z
# Isolate q: q = (y_z * x_a - x_z * y_a) / (y_b * x_a - x_b * y_a)
# Ignore any systems where p and q are not integers.

solve_presses = fn %{a: {xa, ya}, b: {xb, yb}, prize: {xz, yz}} ->
  q = (yz * xa - xz * ya) / (yb * xa - xb * ya)
  if round(q) != q do []
  else
    q = round(q)
    p = (xz - q * xb) / xa
    if round(p) != p, do: [], else: [%{p: round(p), q: q}]
  end
end

count_all = fn d ->
  calc_tokens = fn %{p: p, q: q} -> 3 * p + q end
  Enum.flat_map(d, solve_presses) |> Enum.map(calc_tokens) |> Enum.sum
end

IO.puts("Part 1: #{count_all.(data)}")

adjust_prize = fn %{prize: {px, py}} = machine ->
  %{machine | prize: {px + 10000000000000, py + 10000000000000}}
end

IO.puts("Part 2: #{count_all.(Enum.map(data, adjust_prize))}")
