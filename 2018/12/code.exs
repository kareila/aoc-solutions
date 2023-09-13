# Solution to Advent of Code 2018, Day 12
# https://adventofcode.com/2018/day/12

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_input = fn [init | lines] ->
  init_map = String.trim_leading(init, "initial state: ")
    |> String.graphemes |> Enum.with_index
    |> Enum.reduce(%{}, fn {c, i}, m -> Map.put(m, i, c) end)
  note_map =
    Enum.map(lines, &String.split(&1, " => ")) |>
    Enum.reduce(%{}, fn [k, v], m -> Map.put(m, k, v) end)
  %{state: init_map, notes: note_map}
end

data = read_input.() |> parse_input.()

view_pot = fn i, state ->
  Enum.map_join((i - 2) .. (i + 2), fn pot -> Map.get(state, pot, ".") end)
end

view_all = fn state ->
  Map.keys(state) |> Enum.sort |>
  Enum.map_join(&(state[&1])) |> String.trim(".")
end

tick = fn data ->
  {start, stop} = Enum.min_max(Map.keys(data.state))
  state =
    Enum.reduce((start - 2) .. (stop + 2), %{}, fn pot, state ->
      view = view_pot.(pot, data.state)
      Map.put(state, pot, Map.get(data.notes, view, "."))
    end)
  %{data | state: state}
end

advance = fn data, steps ->
  Enum.reduce(1..steps, data, fn _, data -> tick.(data) end)
end

count_plants = fn data ->
  Map.filter(data.state, fn {_, v} -> v == "#" end) |> Map.keys |> Enum.sum
end

IO.puts("Part 1: #{advance.(data, 20) |> count_plants.()}")


find_steady_state = fn data ->
  Enum.reduce_while(Stream.iterate(1, &(&1 + 1)), data, fn t, prev ->
    {pvis, psum} = {view_all.(prev.state), count_plants.(prev)}
    next = tick.(prev)
    {nvis, nsum} = {view_all.(next.state), count_plants.(next)}
    if pvis != nvis, do: {:cont, next},
    else: {:halt, {t, nsum, nsum - psum}}
  end)
end

billions = fn {t, nsum, diff} -> nsum + (50_000_000_000 - t) * diff end

IO.puts("Part 2: #{find_steady_state.(data) |> billions.()}")
