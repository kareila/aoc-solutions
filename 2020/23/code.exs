# Solution to Advent of Code 2020, Day 23
# https://adventofcode.com/2020/day/23

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

init_data = fn line ->
  cups = String.graphemes(line) |> Enum.map(&String.to_integer/1)
  nxts = Enum.zip(cups, tl(cups) ++ [hd(cups)]) |> Map.new
  {c_min, c_max} = Enum.min_max(cups)
  %{cups: cups, nxts: nxts, min: c_min, max: c_max, cur: hd(cups)}
end

cup_move = fn data ->
  m = data.cur
  n = data.nxts[m]
  o = data.nxts[n]
  p = data.nxts[o]
  q = data.nxts[p]
  chk = fn v -> if v - 1 < data.min, do: data.max, else: v - 1 end
  d =  # select destination
    Enum.reduce_while(Stream.cycle([1]), m, fn _, val ->
      val = chk.(val)
      if val in [n, o, p], do: {:cont, val}, else: {:halt, val}
    end)
  e = data.nxts[d]
  # old order: m -> n -> o -> p -> q, d -> e
  # new order: d -> n -> o -> p -> e, m -> q
  nxts = data.nxts |> Map.put(d, n) |> Map.put(p, e) |> Map.put(m, q)
  %{data | nxts: nxts, cur: q}
end

print_order = fn data, start ->
  Enum.reduce_while(data.nxts, {"", data.nxts[start]}, fn _, {str, n} ->
    if n == start, do: {:halt, str},
    else: {:cont, {str <> "#{n}", data.nxts[n]}}
  end)
end

do_num = fn data, num ->
  Enum.reduce(1..num, data, fn _, data -> cup_move.(data) end)
end

data = read_input.() |> hd |> init_data.()

IO.puts("Part 1: #{do_num.(data, 100) |> print_order.(1)}")


init_more = fn high_val ->
  cups = data.cups ++ Range.to_list((length(data.cups) + 1)..high_val)
  nxts = Enum.zip(cups, tl(cups) ++ [hd(cups)]) |> Map.new
  {c_min, c_max} = Enum.min_max(cups)
  %{nxts: nxts, min: c_min, max: c_max, cur: hd(cups)}
end

find_stars = fn data, n ->
  a = data.nxts[n]
  b = data.nxts[a]
  a * b
end

data = init_more.(1_000_000)

IO.puts("Part 2: #{do_num.(data, 10_000_000) |> find_stars.(1)}")

# elapsed time: approx. 25 sec for both parts together
