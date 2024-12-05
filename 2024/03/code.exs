# Solution to Advent of Code 2024, Day 3
# https://adventofcode.com/2024/day/3

# returns a SINGLE string from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename)
end

data = read_input.()


# get index and string length of all pattern matches
all_matches = fn str, pat ->
  Regex.scan(pat, str, return: :index) |> Enum.concat
end

# transform {idx, length} to {idx, product}
get_muls = fn str ->
  all_matches.(str, ~r/mul\(\d+,\d+\)/) |>
  Enum.map(fn {idx, len} ->
    String.slice(str, idx, len) |> then(&Regex.scan(~r/\d+/, &1)) |>
    Enum.concat |> Enum.map(&String.to_integer/1) |> Enum.product |>
    then(&{idx, &1})
  end)
end

sum_products = fn p -> Enum.map(p, &elem(&1,1)) |> Enum.sum end

IO.puts("Part 1: #{get_muls.(data) |> sum_products.()}")

# evaluate conditionals to discard some products before summing
get_conds = fn muls, str ->
  y = all_matches.(str, ~r/do\(\)/) |>
      Enum.map(fn {idx, _} -> {idx, true} end)
  n = all_matches.(str, ~r/don\'t\(\)/) |> #'
      Enum.map(fn {idx, _} -> {idx, false} end)
  Enum.concat([y, n, muls]) |> Enum.sort |>
  Enum.reduce({true, []}, fn {i, v}, {ok, acc} ->
    case v do
      true -> {true, acc}
      false -> {false, acc}
      v -> {ok, if(ok, do: [{i, v} | acc], else: acc)}
    end
  end) |> elem(1)  # drop ok from the return value
end

IO.puts("Part 2: #{get_muls.(data) |> get_conds.(data) |> sum_products.()}")
