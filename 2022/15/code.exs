# Solution to Advent of Code 2022, Day 15
# https://adventofcode.com/2022/day/15

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# calculate the Manhattan distance between any two points
m_dist = fn {x1, y1}, {x2, y2} -> abs( x1 - x2 ) + abs( y1 - y2 ) end

# At first this looks like another grid mapping problem, but the areas
# are potentially huge (cf. "the row where y=2000000"). Instead, let's
# consider a set of subroutines, where each subroutine, given a y, will
# return a range of x values covered at that y by one sensor.

find_x = fn {x1, y1}, d, y2 ->
  # d = abs( x1 - x2 ) + abs( y1 - y2 ); solve for 2 possible x2 values
  x_diff = d - abs( y1 - y2 )
  if x_diff < 0, do: nil, else: (x1 - x_diff)..(x1 + x_diff)
end

sub_sensor = fn sensor_xy, beacon_xy ->
  fn y -> find_x.(sensor_xy, m_dist.(sensor_xy, beacon_xy), y) end
end

# create a dataset of all sensors and known beacon positions
parse_lines = fn lines ->
  Enum.reduce(lines, %{sensors: [], beacons: %{}}, fn l, data ->
    [x1, y1] = Regex.run(~r/ x=([-]?\d+), y=([-]?\d+):/, l) |> tl
    [x2, y2] = Regex.run(~r/ x=([-]?\d+), y=([-]?\d+)$/, l) |> tl
    [x1, y1, x2, y2] = Enum.map([x1, y1, x2, y2], &String.to_integer/1)
    sensors = [sub_sensor.( {x1, y1}, {x2, y2} ) | data.sensors]
    beacons = Map.put(data.beacons, y2, x2)  # no two beacons share a y2
    %{data | sensors: sensors, beacons: beacons}
  end)
end

collapse_ranges = fn r1, r2 ->
  if Range.disjoint?(r1, r2), do: raise(ArgumentError), else:
  # inputs are sorted, so we always keep the start of r2
  r2.first..Enum.max([r1.last, r2.last])
end

calc_coverage = fn sensors, y ->
  Enum.map(sensors, &(&1.(y))) |> Enum.reject(&is_nil/1) |> Enum.sort
end

check_coverage = fn data, y ->
  coverage = calc_coverage.(data.sensors, y) |> Enum.reduce(collapse_ranges)
  bx = Map.get(data.beacons, y, nil)
  Range.size(coverage) - if(Enum.member?(coverage, bx), do: 1, else: 0)
end

data = read_input.() |> parse_lines.()

IO.puts("Part 1: #{check_coverage.(data, 2_000_000)}")


# For Part 2, find the one value of y between 0 and 4_000_000
# that has disjoint coverage ranges and proceed from there.
#
# Slight timing tweak - answer seems to be on the higher end of y in my
# version of the input, so running backwards to zero resolves faster.

{gap_y, gap_coverage} = Enum.reduce_while(4_000_000..0, data.sensors,
  fn y, sensors ->
    coverage = calc_coverage.(sensors, y)
    try do
      Enum.reduce(coverage, collapse_ranges)
      {:cont, sensors}
    rescue
      _ -> {:halt, {y, coverage}}
    end
  end)
  
gap_ranges = Enum.zip([nil | gap_coverage], gap_coverage) |> tl
gap_x = Enum.reduce_while(gap_ranges, nil, fn {r1, r2}, _ ->
  [x1, x2] = [r1.last, r2.first]
  if x2 - x1 == 2, do: {:halt, x2 - 1}, else: {:cont, nil}
end)

IO.puts("Part 2: #{4_000_000 * gap_x + gap_y}")
