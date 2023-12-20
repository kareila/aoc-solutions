# Solution to Advent of Code 2023, Day 20
# https://adventofcode.com/2023/day/20

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_flipflop = fn str, list ->
  {String.trim_leading(str, "%"), %{type: :f, list: list, state: :off}}
end

parse_conjuction = fn str, list ->
  {String.trim_leading(str, "&"), %{type: :c, list: list, state: %{}}}
end

parse_broadcaster = fn label, list -> {label, %{type: :b, list: list}} end

parse_line = fn line ->
  [name, dests] = String.split(line, " -> ")
  list = String.split(dests, ", ")
  cond do
    String.starts_with?(name, "%") -> parse_flipflop.(name, list)
    String.starts_with?(name, "&") -> parse_conjuction.(name, list)
    String.starts_with?(name, "b") -> parse_broadcaster.(name, list)
  end
end

init_system = fn lines ->
  modules = Map.new(lines, parse_line)
  cs = Map.filter(modules, fn {_, v} -> v.type == :c end) |> Map.keys
  modules = Enum.reduce(modules, modules, fn {k, v}, modules ->
    Enum.reduce(v.list, modules, fn name, modules ->
      if name not in cs, do: modules,
      else: put_in(modules[name].state[k], :low)
    end)
  end)
  %{modules: modules, queue: [], history: %{high: 0, low: 0}, cycles: nil}
end

# Part 2 uses the same "examine the activity and look for primes" trick
# that we saw on Day 8. The node labelled "rx" should have a single
# input that is a "conjunction" module, and we monitor what it receives.
find_rx_inputs = fn %{modules: modules} = data ->
  [src] = Map.filter(modules, fn {_, v} -> "rx" in v.list end) |> Map.keys
  if modules[src].type != :c, do: raise(RuntimeError)
  Map.put(data, :rx, Map.keys(modules[src].state))
end

data = read_input.() |> init_system.() |> find_rx_inputs.()

push_button = fn data -> %{data | queue: [{"broadcaster", :low, nil}]} end

do_flip = fn mod, dest ->
  flip = %{on: :off, off: :on}[mod.state]
  send = %{on: :low, off: :high}[mod.state]
  {%{mod | state: flip}, Enum.map(mod.list, &{&1, send, dest})}
end

do_conj = fn mod, dest, source, pulse ->
  mod = put_in(mod.state[source], pulse)
  send = if Enum.all?(Map.values(mod.state), &(&1 == :high)),
         do: :low, else: :high
  {mod, Enum.map(mod.list, &{&1, send, dest})}
end

process_next = fn %{queue: [{dest, pulse, source} | queue]} = data ->
  data = put_in(data.history[pulse], data.history[pulse] + 1)
  data = if source in data.rx and pulse == :high,
         do: %{data | cycles: source}, else: data
  mod = Map.get(data.modules, dest, %{type: :t})
  {mod, nxt} =
    case mod.type do
      :b -> {mod, Enum.map(mod.list, &{&1, pulse, dest})}
      :f -> if pulse == :high, do: {mod, []}, else: do_flip.(mod, dest)
      :c -> do_conj.(mod, dest, source, pulse)
      :t -> {mod, []}
    end
  %{data | modules: Map.put(data.modules, dest, mod), queue: queue ++ nxt}
end

process_queue = fn data ->
  Enum.reduce_while(Stream.cycle([1]), push_button.(data), fn _, data ->
    data = process_next.(data)
    if Enum.empty?(data.queue), do: {:halt, data}, else: {:cont, data}
  end)
end

repeat_n = fn data, n ->
  Enum.reduce(1..n, data, fn _, data -> process_queue.(data) end).history
end

repeat_with_rx = fn data ->
  Stream.iterate(1, &(&1 + 1)) |>
  Enum.reduce_while({data, %{}}, fn t, {data, cycles} ->
    data = process_queue.(data)
    if is_nil(data.cycles) do {:cont, {data, cycles}}
    else
      cycles = Map.put_new(cycles, data.cycles, t)
      if map_size(cycles) == length(data.rx), do: {:halt, cycles},
      else: {:cont, {%{data | cycles: nil}, cycles}}
    end
  end)
end

final_product = fn d -> Map.values(d) |> Enum.product end

IO.puts("Part 1: #{repeat_n.(data, 1000) |> final_product.()}")
IO.puts("Part 2: #{repeat_with_rx.(data) |> final_product.()}")
