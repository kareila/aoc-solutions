# Solution to Advent of Code 2021, Day 24
# https://adventofcode.com/2021/day/24

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

all_matches = fn str, pat ->
  Regex.scan(pat, str, capture: :all_but_first) |> Enum.concat
end

read_numbers = fn str ->
  all_matches.(str, ~r/(-?\d+)/) |> Enum.map(&String.to_integer/1)
end

# I tried to implement the ALU as described, but that didn't help me find
# the solution. We're going to have to follow the advice to "figure out
# what MONAD does some other way" which I really hate. I'm here to write
# code, not to do algebraic manipulation!! So here's a working algorithm
# that I translated from a Python solution but don't entirely understand.

parse_input = fn lines ->
  Enum.with_index(lines) |>
  Enum.reduce({[], []}, fn {s, i}, {x_add, y_add} ->
    v = read_numbers.(s)
    n = Integer.mod(i, 18)
    x_add = if n == 5,  do: x_add ++ v, else: x_add
    y_add = if n == 15, do: y_add ++ v, else: y_add
    {x_add, y_add}
  end)
end

{x_add, y_add} = read_input.() |> parse_input.()

z_div = Enum.map(x_add, fn n -> if n > 0, do: 1, else: 26 end)

# calculate possible values of z before a single block
# if the final result of evaluating the block is z2
possible_zs = fn i, z2, w ->
  i = if is_nil(i), do: 0, else: i
  cond do
    i < 0 or i >= length(x_add) -> raise RuntimeError, "out of range"
    is_nil(z2) or is_nil(w) -> raise RuntimeError, "bad input (nil)"
    w < 1 or w > 9 -> raise RuntimeError, "bad input (w)"
    true ->
      x = z2 - w - Enum.at(y_add, i)
      r = w - Enum.at(x_add, i)
      zs = if Integer.mod(x, 26) != 0, do: [],
           else: [div(x, 26) * Enum.at(z_div, i)]
      if r >= 0 and r < 26, do: zs ++ [r + z2 * Enum.at(z_div, i)], else: zs
  end
end

solve = fn ws ->
 Enum.with_index(x_add) |> Enum.reverse |>
 Enum.reduce({MapSet.new([0]), %{}}, fn {_, i}, {zs, result} ->
   for w <- ws, z <- MapSet.to_list(zs), z0 <- possible_zs.(i, z, w),
     reduce: {MapSet.new, result} do
       acc ->
         r_z0 = if Map.has_key?(result, z), do: [w | result[z]], else: [w]
         {MapSet.put(elem(acc, 0), z0), Map.put(elem(acc, 1), z0, r_z0)}
   end
 end) |> elem(1) |> Map.fetch!(0) |> Enum.join
end

IO.puts("Part 1: #{solve.(1..9)}")
IO.puts("Part 2: #{solve.(9..1)}")
