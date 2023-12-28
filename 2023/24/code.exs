# Solution to Advent of Code 2023, Day 24
# https://adventofcode.com/2023/day/24

Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_line = fn line ->
  [px, py, pz, vx, vy, vz] = Util.read_numbers(line)
  {{px, py, pz}, {vx, vy, vz}}
end

data = read_input.() |> Enum.map(parse_line)

[minval, maxval] = [200000000000000, 400000000000000]
in_range = fn v -> v >= minval and v <= maxval end

# https://en.wikipedia.org/wiki/Line%E2%80%93line_intersection
intersection = fn {{x1, y1}, {vx1, vy1}}, {{x3, y3}, {vx3, vy3}} ->
  [{x2, y2}, {x4, y4}] = [{x1 + vx1, y1 + vy1}, {x3 + vx3, y3 + vy3}]
  nx = (x1 * y2 - y1 * x2) * (x3 - x4) - (x1 - x2) * (x3 * y4 - y3 * x4)
  ny = (x1 * y2 - y1 * x2) * (y3 - y4) - (y1 - y2) * (x3 * y4 - y3 * x4)
  d = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)
  cond do
    d == 0 -> []
    nx / d < x1 and vx1 > 0 or nx / d < x3 and vx3 > 0 -> []
    nx / d > x1 and vx1 < 0 or nx / d > x3 and vx3 < 0 -> []
    ny / d < y1 and vy1 > 0 or ny / d < y3 and vy3 > 0 -> []
    ny / d > y1 and vy1 < 0 or ny / d > y3 and vy3 < 0 -> []
    true -> [{nx / d, ny / d}]
  end
end

test_area = fn data ->
  dd = Enum.map(data, fn {{x, y, _}, {dx, dy, _}} -> {{x, y}, {dx, dy}} end)
  Enum.reduce(dd, {tl(dd), 0}, fn hs, {rest, tot} ->
    if Enum.empty?(rest) do tot
    else
      Enum.flat_map(rest, &intersection.(&1, hs)) |>
      Enum.count(fn {x, y} -> in_range.(x) and in_range.(y) end) |>
      then(&{tl(rest), tot + &1})
    end
  end)
end

IO.puts("Part 1: #{test_area.(data)}")


diff_map = fn {vel, pts} ->
  Enum.reduce(pts, {tl(pts), []}, fn p, {pts, diffs} ->
    if Enum.empty?(pts), do: Enum.map(diffs, &{vel, &1}),
    else: {tl(pts), diffs ++ Enum.map(pts, &abs(&1 - p))}
  end)
end

solve_v = fn data, i ->
  Enum.group_by(data, &elem(elem(&1, 1), i), &elem(elem(&1, 0), i)) |>
  Enum.filter(fn {_, v} -> length(v) > 1 end) |> Enum.flat_map(diff_map) |>
  Enum.map(fn {vel, dist} ->
    Enum.filter(-500..500, fn v ->
      dv = v - vel
      dv == 0 or Integer.mod(dist, dv) == 0
    end) |> MapSet.new
  end) |> Enum.reduce(&MapSet.intersection/2) |> MapSet.to_list |> hd
end

[my_vx, my_vy, my_vz] = Enum.map(0..2, &solve_v.(data, &1))

modify_stone = fn {{px, py, pz}, {vx, vy, vz}} ->
  {{px, py, pz}, {vx - my_vx, vy - my_vy, vz - my_vz}}
end

intersect_xyz = fn [hs1, hs2] ->
  {{x1, y1, z1}, {vx1, vy1, vz1}} = hs1
  {{x2, y2, z2}, {vx2, vy2, vz2}} = hs2
  [xy1, xy2] = [{{x1, y1}, {vx1, vy1}}, {{x2, y2}, {vx2, vy2}}]
  [xz1, xz2] = [{{x1, z1}, {vx1, vz1}}, {{x2, z2}, {vx2, vz2}}]
  [{px, py}] = intersection.(xy1, xy2)
  [{_, pz}] = intersection.(xz1, xz2)
  Enum.map([px, py, pz], &trunc/1) |> Enum.sum
end

solve_pos = fn data ->
  Enum.take(data, 2) |> Enum.map(modify_stone) |> intersect_xyz.()
end

IO.puts("Part 2: #{solve_pos.(data)}")
