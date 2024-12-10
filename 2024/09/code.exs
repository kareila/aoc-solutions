# Solution to Advent of Code 2024, Day 9
# https://adventofcode.com/2024/day/9

Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_input = fn [line] ->
  String.graphemes(line) |> Enum.map(&String.to_integer/1) |> Enum.with_index
end

data = read_input.() |> parse_input.()


uncompress_blocks = fn list ->
  {free, files} =
    Enum.flat_map(list, fn {v, i} ->
      n = if Integer.mod(i, 2) == 1, do: nil, else: div(i, 2)
      List.duplicate(n, v)
    end) |> Util.list_to_map |>
    Enum.split_with(fn {_, v} -> is_nil(v) end)
  %{free: Enum.map(free, &elem(&1, 0)) |> Enum.sort, files: Map.new(files)}
end

checksum = fn list ->
  Enum.with_index(list) |> Enum.map(fn {v, i} -> v * i end) |> Enum.sum
end

defrag_blocks = fn %{free: free, files: files} ->
  Map.keys(files) |> Enum.sort(:desc) |> Enum.zip(free) |>
  Enum.filter(fn {a, b} -> a > b end) |>
  Enum.reduce(files, fn {old_i, new_i}, files ->
    {v, files} = Map.pop!(files, old_i)
    Map.put(files, new_i, v)
  end) |> Enum.sort |> Enum.map(&elem(&1, 1)) |> checksum.()
end

IO.puts("Part 1: #{uncompress_blocks.(data) |> defrag_blocks.()}")

uncompress_files = fn list ->
  Enum.map(list, fn {v, i} ->
    {if(Integer.mod(i, 2) == 1, do: nil, else: div(i, 2)), v}
  end) |> Enum.reject(& &1 == {nil, 0})
end

find_space = fn list, sz ->
  Enum.find_index(list, fn {fid, fsz} -> is_nil(fid) and fsz >= sz end)
end

defrag_files = fn list ->
  Enum.reject(tl(list), fn {id, _} -> is_nil(id) end) |> Enum.reverse |>
  Enum.reduce(list, fn {id, sz}, list ->
    move_i = find_space.(list, sz)
    curr_i = Enum.find_index(list, & &1 == {id, sz})
    if is_nil(move_i) or curr_i < move_i do list
    else
      {_, fsz} = Enum.at(list, move_i)
      list = List.replace_at(list, curr_i, {nil, sz})
      if sz == fsz do list
      else List.insert_at(list, move_i + 1, {nil, fsz - sz})
      end |> List.replace_at(move_i, {id, sz})
    end
  end) |>
  Enum.flat_map(fn {n, len} ->
    n = if is_nil(n), do: 0, else: n
    List.duplicate(n, len)
  end) |> checksum.()
end

IO.puts("Part 2: #{uncompress_files.(data) |> defrag_files.()}")

# elapsed time: approx. 2.9 sec for both parts together
# (because modifying large lists in Elixir is slow)
