# Solution to Advent of Code 2017, Day 16
# https://adventofcode.com/2017/day/16

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_move = fn s ->
  {t, m} = String.split_at(s, 1)
  case t do
    "s" -> {t, String.to_integer(m)}
    "x" -> {t, String.split(m, "/") |> Enum.map(&String.to_integer/1)}
    "p" -> {t, String.split(m, "/")}
  end
end

parse_input = fn line -> String.split(line, ",") |> Enum.map(parse_move) end

do_s = fn group, amt ->
  {leave, taken} = Enum.split(group, -amt)
  leave = Enum.map(leave, fn {v, i} -> {v, i + amt} end)
  taken = Enum.map(taken, fn {v, _} -> v end) |> Enum.with_index
  taken ++ leave
end

do_x = fn group, [ai, bi] ->
  {a, group} = List.keytake(group, ai, 1)
  {b, group} = List.keytake(group, bi, 1)
  group ++ [{elem(a, 0), bi}, {elem(b, 0), ai}] |> List.keysort(1)
end

do_p = fn group, [av, bv] ->
  {a, group} = List.keytake(group, av, 0)
  {b, group} = List.keytake(group, bv, 0)
  group ++ [{av, elem(b, 1)}, {bv, elem(a, 1)}] |> List.keysort(1)
end

steps = read_input.() |> hd |> parse_input.()

dance = fn init ->
  Enum.reduce(steps, init, fn {t, move}, group ->
    f = %{"s" => do_s, "x" => do_x, "p" => do_p} |> Map.fetch!(t)
    f.(group, move)
  end)
end

print_group = fn group -> Enum.map_join(group, &elem(&1,0)) end

init_group = ?a..?p |> Enum.map(fn c -> <<c>> end) |> Enum.with_index

IO.puts("Part 1: #{dance.(init_group) |> print_group.()}")


# Looks like today's One Weird Trick is cycle detection.
cycle_dances = fn num ->
  {group, repeat, t} =
    Enum.reduce_while(1..num, {init_group, %{}}, fn t, {group, snapshots} ->
      group = dance.(group)
      snap = print_group.(group)
      if Map.has_key?(snapshots, snap),
      do: {:halt, {group, t - snapshots[snap], t}},
      else: {:cont, {group, Map.put(snapshots, snap, t)}}
    end)
  t =
    Enum.reduce_while(Stream.cycle([repeat]), t, fn p, t ->
      if t + p > num, do: {:halt, t + 1}, else: {:cont, t + p}
    end)
  Enum.reduce(t..num, group, fn _, group -> dance.(group) end)
end

IO.puts("Part 2: #{cycle_dances.(1_000_000_000) |> print_group.()}")
