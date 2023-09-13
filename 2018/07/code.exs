# Solution to Advent of Code 2018, Day 7
# https://adventofcode.com/2018/day/7

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_line = fn line, {starts, stops} ->
  [_, start, stop] =
    Regex.run(~r/Step (\S+) must be finished before step (\S+)/, line)
  starts = Map.update(starts, start, [stop], &([stop | &1]))
  {starts, Map.update(stops, stop, [start], &([start | &1]))}
end

parse_lines = fn lines -> Enum.reduce(lines, {%{}, %{}}, parse_line) end

data = read_input.() |> parse_lines.()

process_start = fn start, starts, stops ->
  Enum.reduce(starts[start], {starts, stops}, fn stop, {starts, stops} ->
    if stops[stop] == [start] do
      {Map.put_new(starts, stop, []), Map.delete(stops, stop)}
    else
      {starts, Map.replace!(stops, stop, stops[stop] -- [start])}
    end
  end)
end

process_nexts = fn starts, stops ->
  Enum.reject(Map.keys(starts), fn k -> k in Map.keys(stops) end) |> Enum.sort
end

find_order = fn ->
  init = Tuple.append(data, "")
  Enum.reduce_while(Stream.cycle([1]), init, fn _, {starts, stops, order} ->
    if Enum.empty?(starts) do {:halt, order}
    else
      nxt = process_nexts.(starts, stops) |> hd
      {starts, stops} = process_start.(nxt, starts, stops)
      {:cont, {Map.delete(starts, nxt), stops, order <> nxt}}
    end
  end)
end

IO.puts("Part 1: #{find_order.()}")


alpha = ?A..?Z |> Enum.with_index(1) |> Map.new(fn {c, i} -> {<<c>>, i} end)

map_dec = fn w ->
  Map.new(w, fn {k, v} -> {k, if(v == 0, do: 0, else: v - 1)} end)
end

zero_keys = fn w ->
  Enum.flat_map(w, fn {k, v} -> if v == 0, do: [k], else: [] end)
end

find_multi = fn {starts, stops}, num_workers, duration ->
  workers = Range.to_list(1..num_workers) |> Map.from_keys(0)
  Enum.reduce_while(Stream.iterate(0, &(&1 + 1)), {starts, stops, workers, %{}},
    fn tick, {starts, stops, workers, active} ->
      unstarted = process_nexts.(starts, stops) -- Map.values(active)
      available = Enum.zip(unstarted, zero_keys.(workers))
      {workers, active} =
        Enum.reduce(available, {workers, active}, fn {nxt, who}, {workers, active} ->
          {Map.put(workers, who, alpha[nxt] + duration), Map.put(active, who, nxt)}
        end)
      if Enum.empty?(unstarted) and Enum.empty?(active) do {:halt, tick}
      else
        workers = map_dec.(workers)
        done = zero_keys.(workers) |> Enum.filter(&Map.has_key?(active, &1))
        {starts, stops} =
          Enum.reduce(done, {starts, stops}, fn worker, {starts, stops} ->
            start = Map.fetch!(active, worker)
            {starts, stops} = process_start.(start, starts, stops)
            {Map.delete(starts, start), stops}
          end)
        {:cont, {starts, stops, workers, Map.drop(active, done)}}
      end
    end)
end

IO.puts("Part 2: #{find_multi.(data, 5, 60)}")
