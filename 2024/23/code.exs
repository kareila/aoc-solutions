# Solution to Advent of Code 2024, Day 23
# https://adventofcode.com/2024/day/23

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

in_both = fn m, a, b ->
  m |> Map.update(a, [b], &[b | &1]) |> Map.update(b, [a], &[a | &1])
end

parse_input = fn lines ->
  Enum.reduce(lines, {%{}, MapSet.new}, fn s, {links, ids} ->
    [a, b] = String.split(s, "-")
    {in_both.(links, a, b), MapSet.new([a, b]) |> MapSet.union(ids)}
  end)
end

find_three = fn links, ids ->
  chk1 = Enum.take(ids, 1) |> hd
  Enum.reduce_while(Stream.cycle([1]), links[chk1], fn _, list ->
    if Enum.empty?(list) do {:halt, chk1}
    else
      [chk2 | list] = list
      chk3s = Enum.filter(list, & &1 in links[chk2])
      if Enum.empty?(chk3s), do: {:cont, list},
      else: {:halt, {chk1, chk2, chk3s}}
    end
  end)
end

find_all_threes = fn {links, ids} ->
  Enum.reduce_while(Stream.cycle([1]), {MapSet.new, links, ids},
    fn _, {threes, links, ids} ->
      if Enum.empty?(ids) do {:halt, threes}
      else
        chk = find_three.(links, ids)
        if is_tuple(chk) do
          {chk1, chk2, chk3s} = chk
          links = Map.replace!(links, chk1, links[chk1] -- [chk2])
          threes =
            Enum.reduce(chk3s, threes, fn chk3, threes ->
              MapSet.put(threes, Enum.sort([chk1, chk2, chk3]))
            end)
          {:cont, {threes, links, ids}}
        else
          {:cont, {threes, links, MapSet.delete(ids, chk)}}
        end
      end
    end)
end

count_ts = fn threes ->
  Enum.count(threes, fn list ->
    Enum.any?(list, &String.starts_with?(&1, "t"))
  end)
end

data = read_input.() |> parse_input.()
threes = find_all_threes.(data)

IO.puts("Part 1: #{count_ts.(threes)}")

next_candidate = fn list, links, ids, done ->
  if MapSet.member?(done, list) do nil
  else
    nxt = MapSet.difference(ids, MapSet.new(list)) |> MapSet.to_list
    chk =
      Enum.reduce_while(Map.take(links, nxt), nil, fn {k, v}, _ ->
        if Enum.all?(list, & &1 in v), do: {:halt, k}, else: {:cont, nil}
      end)
    if is_nil(chk), do: MapSet.put(done, list), else: chk
  end
end

find_next_member = fn sets, links, ids, cache ->
  Enum.reduce_while(sets, cache, fn list, cache ->
    chk = next_candidate.(list, links, ids, cache)
    cond do
      is_nil(chk) -> {:cont, cache}
      is_map(chk) -> {:cont, chk}
      true -> {:halt, {[chk | list] |> Enum.sort, cache}}
    end
  end)
end

coalesce = fn threes, {links, ids} ->
  init = {MapSet.new, threes}
  Enum.reduce_while(Stream.cycle([1]), init, fn _, {cache, sets} ->
    nxt = find_next_member.(sets, links, ids, cache)
    if is_map(nxt) do {:halt, sets}
    else
      {nxt, cache} = nxt
      Enum.reduce(sets, sets, fn s, sets ->
        if not Enum.all?(s, & &1 in nxt), do: sets,
        else: MapSet.delete(sets, s)
      end) |> MapSet.put(nxt) |> then(&{:cont, {cache, &1}})
    end
  end) |> Enum.max_by(&length/1) |> Enum.join(",")
end

IO.puts("Part 2: #{coalesce.(threes, data)}")

# elapsed time: approx. 3.9 sec for both parts together
