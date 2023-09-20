# Solution to Advent of Code 2021, Day 2
# https://adventofcode.com/2021/day/2

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_input = fn lines ->
  Enum.map(lines, fn line -> String.split(line) |> List.to_tuple end) |>
  Enum.map(fn {k, v} -> {k, String.to_integer(v)} end)
end

data = read_input.() |> parse_input.()

calc_one = fn ->
  Enum.reduce(data, {0, 0}, fn {move, amt}, {pos, depth} ->
    case move do
      "forward" -> {pos + amt, depth}
      "down" -> {pos, depth + amt}
      "up" -> {pos, depth - amt}
    end
  end) |> Tuple.product
end

IO.puts("Part 1: #{calc_one.()}")


calc_two = fn ->
  Enum.reduce(data, {0, 0, 0}, fn {move, amt}, {pos, depth, aim} ->
    case move do
      "forward" -> {pos + amt, depth + (aim * amt), aim}
      "down" -> {pos, depth, aim + amt}
      "up" -> {pos, depth, aim - amt}
    end
  end) |> Tuple.delete_at(2) |> Tuple.product
end

IO.puts("Part 2: #{calc_two.()}")
