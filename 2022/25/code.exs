# Solution to Advent of Code 2022, Day 25
# https://adventofcode.com/2022/day/25

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_snafu = fn str ->
  d = %{"2" => 2, "1" => 1, "0" => 0, "-" => -1, "=" => -2}
  String.graphemes(str) |> Enum.reverse |> Enum.map(&Map.fetch!(d, &1)) |>
  Enum.with_index |> Enum.map(fn {n, i} -> n * Integer.pow(5, i) end) |>
  Enum.sum
end

output_snafu = fn num ->
  Enum.reduce_while(Stream.iterate(0, &(&1 + 1)), {num, []},
  fn max_place, {num, col} ->
    if num == 0 do {:halt, Enum.join(col)}
    else
      b_mod = Integer.pow(5, max_place)
      n_mod = b_mod * 5
      bit = Integer.mod(num, n_mod)
      [num, bit] = [num - bit, div(bit, b_mod)]
      case bit do
        3 -> {:cont, {num + n_mod, ["=" | col]}}
        4 -> {:cont, {num + n_mod, ["-" | col]}}
        bit -> {:cont, {num, [bit | col]}}
      end
    end
  end)
end

total = read_input.() |> Enum.map(parse_snafu) |> Enum.sum

IO.puts("Part 1: #{output_snafu.(total)}")

# There is no Part 2!  Merry Christmas!
