# Solution to Advent of Code 2022, Day 18
# https://adventofcode.com/2022/day/18

require Recurse  # for search()

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_lines = fn lines ->
  Enum.reduce(lines, MapSet.new, fn l, data ->
    [x, y, z] = String.split(l, ",") |> Enum.map(&String.to_integer/1)
    MapSet.put(data, {x,y,z})
  end)
end

data = read_input.() |> parse_lines.()

# check each value's six neighbors for exposed faces
count = Enum.reduce(data, 0, fn {x,y,z}, ct ->
  f = [{x-1,y,z}, {x+1,y,z}, {x,y-1,z}, {x,y+1,z}, {x,y,z-1}, {x,y,z+1}]
  ct + 6 - Enum.count(f, &MapSet.member?(data, &1))
end)

IO.puts("Part 1: #{count}")


# calculate upper and lower bounds in all dimensions
# I thought I could assume 1's for minimums here, but I was wrong...
{min_x, max_x} = Enum.map(data, &elem(&1,0)) |> Enum.min_max
{min_y, max_y} = Enum.map(data, &elem(&1,1)) |> Enum.min_max
{min_z, max_z} = Enum.map(data, &elem(&1,2)) |> Enum.min_max

limits = %{min_x: min_x - 1, min_y: min_y - 1, min_z: min_z - 1,
           max_x: max_x + 1, max_y: max_y + 1, max_z: max_z + 1}

# start searching at max and go down in all directions
# (add one to get past the edge of the surface)
{_, count} = {limits.max_x, limits.max_y, limits.max_z}
  |> Recurse.search(data, limits, MapSet.new, 0)

IO.puts("Part 2: #{count}")
