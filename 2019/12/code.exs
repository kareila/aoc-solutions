# Solution to Advent of Code 2019, Day 12
# https://adventofcode.com/2019/day/12

Code.require_file("Matrix.ex", "..")
Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

init_system = fn line ->
  Util.read_numbers(line) |> then(&(%{pos: &1, vel: [0,0,0]}))
end

list_add = fn list1, list2 -> Enum.zip_with(list1, list2, &+/2) end

apply_gravity = fn system ->
  Enum.map(system, fn moon1 ->
    vel =
      Enum.reduce(system -- [moon1], moon1.vel, fn moon2, vel ->
        Enum.zip_with(moon1.pos, moon2.pos, fn p1, p2 ->
          cond do
            p1 < p2 -> 1
            p1 > p2 -> -1
            true -> 0
          end
        end) |> list_add.(vel)
      end)
    %{moon1 | vel: vel}
  end)
end

apply_velocity = fn system ->
  Enum.map(system, fn moon ->
    %{moon | pos: list_add.(moon.pos, moon.vel)}
  end)
end

time_step = fn sys -> apply_gravity.(sys) |> apply_velocity.() end

simulate = fn system, num_steps ->
  Enum.reduce(1..num_steps, system, fn _, sys -> time_step.(sys) end)
end

energy = fn list -> Enum.map(list, &Kernel.abs/1) |> Enum.sum end

total_energy = fn moon ->
  Map.values(moon) |> Enum.map(energy) |> Enum.product
end

system_energy = fn sys -> Enum.map(sys, total_energy) |> Enum.sum end

data = read_input.() |> Enum.map(init_system)

IO.puts("Part 1: #{simulate.(data, 1000) |> system_energy.()}")


# Instead of computing the cycle time for the entire system,
# compute the cycle time for each independent axis separately,
# and then find the least common multiple of those three numbers.
lcm = fn a, b -> div(a * b, Integer.gcd(a, b)) end

remap = fn axis -> for [p, v] <- axis, do: %{pos: [p], vel: [v]} end

split_system = fn system ->
  Enum.map(system, &Matrix.transpose([&1.pos, &1.vel])) |>
  Matrix.transpose |> Enum.map(remap)
end

find_cycle = fn init_axis ->
  Enum.reduce_while(Stream.iterate(1, &(&1 + 1)), init_axis, fn n, axis ->
    axis = time_step.(axis)
    if axis == init_axis, do: {:halt, n}, else: {:cont, axis}
  end)
end

cycle_all = fn axis_list ->
  Enum.map(axis_list, find_cycle) |> Enum.reduce(lcm)
end

IO.puts("Part 2: #{split_system.(data) |> cycle_all.()}")
