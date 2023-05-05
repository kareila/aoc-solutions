# Solution to Advent of Code 2022, Day 10
# https://adventofcode.com/2022/day/10

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# "during the first cycle" cycle is 1, so no defined zero value
init_system = fn -> %{ cycle: [nil], x: 1 } end

noop = fn sys -> %{sys | cycle: [sys.x | sys.cycle]} end

addx = fn sys, v ->
  sys = sys |> noop.() |> noop.()  # two cycles
  %{sys | x: sys.x + v}
end
  
parse_line = fn l, sys ->
  case String.split(l) do
    ["addx", num_str] -> addx.(sys, String.to_integer(num_str))
    ["noop"] -> noop.(sys)
  end
end

run_cycles = fn lines ->
  sys = Enum.reduce(lines, init_system.(), parse_line)
  Enum.reverse(sys.cycle)  # because we built the list by prepending
end

calc_cycles = fn cycles ->
  Enum.map(20..220//40, fn i -> i * Enum.at(cycles, i) end) |> Enum.sum
end

cycles = read_input.() |> run_cycles.()

IO.puts("Part 1: #{calc_cycles.(cycles)}")


cycles = tl(cycles)  # drop the undef to keep display in sync

init_crt = fn -> %{ i: 0, row: [], values: [] } end

advance_row = fn crt ->
  if crt.i != 40, do: crt, else:  # new row every 40 pixels
  %{values: [crt.row | crt.values], row: [], i: 0}
end

do_pixel = fn x, crt ->
  sprite = if(crt.i in x - 1 .. x + 1, do: "#", else: ".")
  %{crt | row: [sprite | crt.row], i: crt.i + 1} |> advance_row.()
end

crt = Enum.reduce(cycles, init_crt.(), do_pixel)
output = Enum.map_join(crt.values, "\n", &Enum.join/1) |> String.reverse

IO.puts("Part 2:\n#{output}")
