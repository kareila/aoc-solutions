# Solution to Advent of Code 2023, Day 19
# https://adventofcode.com/2023/day/19

Code.require_file("Util.ex", "..")
Code.require_file("Recurse.ex", ".")

# returns a list of non-blank BLOCKS from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n\n", trim: true)
end

parse_test = fn str ->
  [_, xmas, op, num] = Regex.run(~r/^([xmas])(\D)(\d+)$/, str)
  op = %{">" => &>/2, "<" => &</2} |> Map.fetch!(op)
  %{xmas: xmas, op: op, num: String.to_integer(num)}
end

parse_workflow = fn line ->
  [name, rest] = String.split(line, "{")
  rules = String.trim_trailing(rest, "}") |> String.split(",")
  {rules, [default]} = Enum.split(rules, -1)
  rules = Enum.map(rules, &String.split(&1, ":")) |>
          Enum.map(fn [t, d] -> %{test: parse_test.(t), dest: d} end)
  {name, rules ++ [%{test: nil, dest: default}]}
end

parse_part = fn line ->
  [x, m, a, s] = Util.read_numbers(line)
  %{"x" => x, "m" => m, "a" => a, "s" => s}
end

parse_input = fn blocks ->
  [w, p] = Enum.map(blocks, &String.split(&1, "\n", trim: true))
  %{workflows: Map.new(w, parse_workflow), parts: Enum.map(p, parse_part)}
end

# Tracing every acceptance path through the workflows (needed for Part 2).
# All paths start at "in" and all possible values are in the range 1..4000.
parse_chains = fn data -> Recurse.chains("in", data.workflows) end

parse_ranges = fn c ->
  Enum.reduce(Enum.reject(tl(c), &is_nil/1), %{}, fn {negate?, t}, set ->
    lt? = t.op.(t.num - 1, t.num)
    op = if negate?, do: %{true: :gte, false: :lte}[lt?],
         else: %{true: :lt, false: :gt}[lt?]
    matched =
      %{gte: t.num..4000, gt: (t.num + 1)..4000,
        lt: 1..(t.num - 1), lte: 1..t.num} |> Map.fetch!(op)
    Map.update(set, t.xmas, [matched], &[matched | &1])
  end) |>
  Map.new(fn {k, v} ->  # calculate intersection of each list of ranges
    if length(v) == 1 do {k, hd(v)}
    else
      Enum.reduce(v, fn a, b ->
        Range.new(Enum.max([a.first, b.first]), Enum.min([a.last, b.last]))
      end) |> then(&{k, &1})
    end
  end)
end

parse_paths = fn data ->
  Map.put(data, :paths, Enum.map(parse_chains.(data), parse_ranges))
end

data = read_input.() |> parse_input.() |> parse_paths.()

check_part = fn part, paths ->
  Enum.any?(paths, fn p ->
    Enum.all?(~w(x m a s)s, fn xmas ->
      part[xmas] in Map.get(p, xmas, 1..4000)
    end)
  end)
end

check_all = fn %{paths: paths, parts: pts} ->
  Enum.filter(pts, &check_part.(&1, paths)) |>
  Enum.flat_map(&Map.values/1) |> Enum.sum
end

IO.puts("Part 1: #{check_all.(data)}")


calculate_combo = fn set ->
  Enum.reduce(~w(x m a s)s, set, fn k, set ->
    Map.put_new(set, k, 1..4000)
  end) |> Map.values |> Enum.map(&Range.size/1) |> Enum.product
end

combos = Enum.map(data.paths, calculate_combo)

IO.puts("Part 2: #{Enum.sum(combos)}")
