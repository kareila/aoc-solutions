# Solution to Advent of Code 2024, Day 24
# https://adventofcode.com/2024/day/24

Code.require_file("Util.ex", "..")

# returns TWO lists of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n\n") |>
  Enum.map(&String.split(&1, "\n", trim: true))
end

parse_input = fn [known, gates] ->
  known_map = known |> Map.new(&List.to_tuple(String.split(&1, ": ")))
  gates_map = gates |> Enum.map(&Util.all_matches(&1, ~r/(\S+)/)) |>
    Map.new(fn [in1, op, in2, _, out] -> {{op, out}, {in1, in2}} end)
  if map_size(gates_map) != length(gates), do: raise RuntimeError
  %{known: known_map, gates: gates_map}
end

next_known = fn gates, known ->
  Enum.reduce_while(Map.values(gates), nil, fn {a, b}, _ ->
    if is_map_key(known, a) and is_map_key(known, b),
    do: {:halt, {a, b}}, else: {:cont, nil}
  end)
end

all_outputs = fn gates, in1, in2 ->
  Enum.flat_map_reduce(gates, gates, fn {k, v}, gates ->
    if v in [{in1, in2}, {in2, in1}],
    do: {[k], Map.delete(gates, k)}, else: {[], gates}
  end)
end

step = fn %{known: known, gates: gates} ->
  {in1, in2} = next_known.(gates, known)
  {v1, v2} = {known[in1], known[in2]}
  {outs, gates} = all_outputs.(gates, in1, in2)
  known =
    Enum.reduce(outs, known, fn {op, out}, known ->
      if is_map_key(known, out), do: raise RuntimeError
      case op do
        "AND" -> if v1 == "1" and v2 == "1", do: "1", else: "0"
        "OR"  -> if v1 == "1" or  v2 == "1", do: "1", else: "0"
        "XOR" -> if v1 != v2, do: "1", else: "0"
      end |> then(&Map.put(known, out, &1))
    end)
  %{known: known, gates: gates}
end

calculate_all = fn data ->
  Enum.reduce_while(Stream.cycle([1]), data, fn _, data ->
    data = step.(data)
    if Enum.empty?(data.gates), do: {:halt, data.known}, else: {:cont, data}
  end)
end

s_value = fn known, s ->
  Map.keys(known) |> Enum.filter(&String.starts_with?(&1, s)) |>
  Enum.sort(:desc) |> Enum.map_join(&Map.fetch!(known, &1)) |>
  String.to_integer(2)
end

z_value = fn known -> s_value.(known, "z") end

data = read_input.() |> parse_input.()

IO.puts("Part 1: #{calculate_all.(data) |> z_value.()}")

# I initially solved Part 2 by inspection, and later adapted the following
# automatic solution from a Python script I saw posted as a Reddit comment.

find_swaps = fn data ->
  Enum.flat_map(data.gates, fn {{op, out}, {in1, in2}} ->
    start = %{out: String.first(out), in1: String.first(in1),
                                      in2: String.first(in2)}
    cond do
      start.out == "z" and op != "XOR" and out != "z45" -> [out]
      Enum.all?(Map.values(start), & &1 not in ["x", "y", "z"]) and
        op == "XOR" -> [out]
      op == "AND" and "x00" not in [in1, in2] and
        Enum.any?(data.gates, fn {{sop, _}, {sin1, sin2}} ->
          out in [sin1, sin2] and sop != "OR" end) -> [out]
      op == "XOR" and Enum.any?(data.gates, fn {{sop, _}, {sin1, sin2}} ->
        out in [sin1, sin2] and sop == "OR" end) -> [out]
      true -> []            
    end
  end) |> Enum.sort
end

IO.puts("Part 2: #{Enum.join(find_swaps.(data), ",")}")

# See also: https://www.reddit.com/r/adventofcode/comments/1hl698z/2024_day_24_solutions/
