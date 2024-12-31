# Solution to Advent of Code 2024, Day 22
# https://adventofcode.com/2024/day/22

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

mix_and_prune = fn s, num -> Bitwise.bxor(num, s) |> rem(16777216) end

evolve = fn n ->
  m = mix_and_prune.(n, n * 64)
  n = mix_and_prune.(m, div(m, 32))
  mix_and_prune.(n, n * 2048)
end

simulate_all = fn lines ->
  Enum.map(lines, fn n ->
    Enum.reduce(1..2000, [String.to_integer(n)], fn _, history ->
      [evolve.(hd(history)) | history]
    end)
  end)
end

data = read_input.() |> simulate_all.()


sum_final_secrets = fn list -> Enum.map(list, &hd/1) |> Enum.sum end

IO.puts("Part 1: #{sum_final_secrets.(data)}")

analyze_sequence = fn list ->
  seq = Enum.map(Enum.reverse(list), &rem(&1, 10))
  chg = Enum.zip_with(tl(seq), seq, &-/2)
  vals = Enum.zip(tl(seq), chg)
  Enum.reduce(Enum.drop(vals, 3), {%{}, vals}, fn _, {found, vals} ->
    {seq4, chg4} = Enum.take(vals, 4) |> Enum.unzip
    {Map.put_new(found, chg4, List.last(seq4)), tl(vals)}
  end) |> elem(0)
end

analyze_all = fn data ->
  Task.async_stream(data, analyze_sequence) |>
  Stream.map(fn {:ok, v} -> v end) |>
  Enum.reduce(&Map.merge(&1, &2, fn _k, v1, v2 -> v1 + v2 end)) |>
  Map.values |> Enum.max
end

IO.puts("Part 2: #{analyze_all.(data)}")

# elapsed time: approx. 2.9 sec for both parts together
