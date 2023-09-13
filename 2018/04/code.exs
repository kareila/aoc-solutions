# Solution to Advent of Code 2018, Day 4
# https://adventofcode.com/2018/day/4

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# In the real data, sometimes the guard shows up before midnight
# on the day before, but they never fall asleep before midnight...
# just make sure the log lines are sorted before parsing.

parse_lines = fn lines ->
  {data, curr} =
    Enum.reduce(lines, {[], nil}, fn line, {data, curr} ->
      [_, minute, log] = Regex.run(~r/:(\d+)] (.*)$/, line)
      minute = String.to_integer(minute)
      cond do
        log == "falls asleep" -> {data, Map.update!(curr, :sleeps, &([minute | &1]))}
        log == "wakes up" -> {data, Map.update!(curr, :wakes, &([minute | &1]))}
        true ->
          [_, id] = Regex.run(~r/^Guard .(\d+)/, log)
          {[curr | data], %{id: id, sleeps: [], wakes: []}}
      end
    end)
  List.replace_at(data, -1, curr)  # replaces the nil
end

count_minutes = fn data ->
  Enum.reduce(data, %{}, fn day, counts ->
    counts = Map.put_new(counts, day.id, %{})
    Enum.zip(day.sleeps, day.wakes) |>
    Enum.flat_map(fn {s, w} -> Range.to_list(s .. (w - 1)) end) |>
    Map.from_keys(1) |> Map.merge(counts[day.id], fn _, v1, v2 -> v1 + v2 end) |>
    then(&Map.put(counts, day.id, &1))
  end)
end

data = read_input.() |> Enum.sort |> parse_lines.() |> count_minutes.()

find_by = fn search_fn ->
  Enum.reduce(data, %{}, fn {guard, minutes}, counts ->
    Map.put(counts, guard, search_fn.(Map.values(minutes)))
  end) |> Enum.max_by(&elem(&1,1))
end

multiplier = fn val, guard -> elem(val, 0) * String.to_integer(guard) end

find_biggest_sleeper = fn ->
  {guard, _total} = find_by.(&Enum.sum/1)
  Enum.max_by(data[guard], fn {_, v} -> v end) |> multiplier.(guard)
end

IO.puts("Part 1: #{find_biggest_sleeper.()}")


find_biggest_minute = fn ->
  {guard, most} = find_by.(&Enum.max(&1, fn -> 0 end))
  Enum.find(data[guard], fn {_, v} -> v == most end) |> multiplier.(guard)
end

IO.puts("Part 2: #{find_biggest_minute.()}")
