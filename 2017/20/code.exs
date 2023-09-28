# Solution to Advent of Code 2017, Day 20
# https://adventofcode.com/2017/day/20

Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_line = fn line ->
  [p, v, a] = Util.read_numbers(line) |>
              Enum.chunk_every(3) |> Enum.map(&List.to_tuple/1)
  %{p: p, v: v, a: a}
end

data = read_input.() |> Enum.map(parse_line) |> Enum.with_index

o_dist = fn p -> Util.m_dist(p, {0,0,0}) end

closest =
  Enum.min_by(data, fn {d, _} -> o_dist.(d.a) end) |> elem(1)

IO.puts("Part 1: #{closest}")


step_p = fn %{p: {px, py, pz}, v: {vx, vy, vz}, a: {ax, ay, az}} ->
  %{p: {px + vx + ax, py + vy + ay, pz + vz + az},
    v: {vx + ax, vy + ay, vz + az}, a: {ax, ay, az}}
end

step_all = fn data -> Enum.map(data, fn {d, i} -> {step_p.(d), i} end) end

list_collided = fn data ->
  Enum.map(data, fn {d, i} -> {d.p, i} end) |> Util.group_tuples(0, 1) |>
  Map.values |> Enum.filter(&(length(&1) > 1)) |> List.flatten
end

remove_collided = fn data ->
  lsc = list_collided.(data)
  Enum.reject(data, fn {_, i} -> i in lsc end)
end

tick = fn data -> step_all.(data) |> remove_collided.() end

min_distance = fn data ->
  Enum.map(data, fn {d, _} -> o_dist.(d.p) end) |> Enum.min
end

# I couldn't easily determine a good stop condition. This seems to work?
resolve = fn ->
  Enum.reduce_while(Stream.cycle([1]), data, fn _, data ->
    if min_distance.(data) > 1000, do: {:halt, length(data)},
    else: {:cont, tick.(data)}
  end)
end

IO.puts("Part 2: #{resolve.()}")
