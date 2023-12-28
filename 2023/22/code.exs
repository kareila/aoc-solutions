# Solution to Advent of Code 2023, Day 22
# https://adventofcode.com/2023/day/22

Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_line = fn line ->
  [x1, y1, z1, x2, y2, z2] = Util.read_numbers(line)
  %{x: x1..x2, y: y1..y2, z: z1..z2}
end

brick_to_points = fn {%{x: x, y: y, z: z}, v} ->
  for i <- x, j <- y, k <- z, do: {{i, j, k}, v}
end

init_data = fn lines ->
  bricks = Enum.map(lines, parse_line) |> Enum.with_index(1)
  grid = Enum.flat_map(bricks, brick_to_points) |> Map.new
  %{grid: grid, bricks: 1..length(bricks)}
end

move_down = fn pts, grid ->
  Enum.reduce_while(Stream.cycle([1]), pts, fn _, pts ->
    nxt = Enum.map(pts, fn {x, y, z} -> {x, y, z - 1} end)
    open? = fn n -> n in pts or not is_map_key(grid, n) end
    cond do
      Enum.any?(nxt, fn {_, _, z} -> z < 1 end) -> {:halt, pts}
      Enum.all?(nxt, open?) -> {:cont, nxt}
      true -> {:halt, pts}
    end
  end)
end

z_order = fn b_map ->
  z_min = fn pts -> Enum.map(pts, &elem(&1, 2)) |> Enum.min end
  Enum.map(b_map, fn {b, pts} -> {b, z_min.(pts)} end) |>
  Util.group_tuples(1, 0) |> Map.to_list |> List.keysort(0)
end

descent = fn %{grid: grid} ->
  b_map = Util.group_tuples(grid, 1, 0)
  Enum.flat_map(z_order.(b_map), &elem(&1, 1)) |>
  Enum.reduce(grid, fn bi, grid ->
    pts = Map.fetch!(b_map, bi)
    nxt = move_down.(pts, grid)
    Map.drop(grid, pts) |> Map.merge(Map.from_keys(nxt, bi))
  end)
end

connections = fn data ->
  grid = descent.(data)
  b_map = Util.group_tuples(grid, 1, 0)
  Enum.reduce(data.bricks, {%{}, %{}}, fn bi, {on_count, supported_by} ->
    pts = Map.fetch!(b_map, bi)
    open? = fn n -> n in pts or not is_map_key(grid, n) end
    under = Enum.map(pts, fn {x, y, z} -> {x, y, z - 1} end) |>
            Enum.reject(open?)
    on = Map.filter(b_map, fn {_, v} -> Enum.any?(v, &(&1 in under)) end)
    supported_by =
      Enum.reduce(Map.keys(on), supported_by, fn s, supported_by ->
        Map.update(supported_by, s, [bi], &[bi | &1])
      end)
    {Map.put(on_count, bi, map_size(on)), supported_by}
  end)
end

data = read_input.() |> init_data.()
{on_count, supported_by} = connections.(data)

{pt1, pt2} =
  Enum.reduce(data.bricks, {0, 0}, fn bi, {safe, drops} ->
    nxt_open = fn o -> Map.get(supported_by, o, []) end
    Enum.reduce_while(Stream.cycle([1]), {nxt_open.(bi), %{}, 0},
      fn _, {open, support_loss, drops} ->
        if Enum.empty?(open) do {:halt, drops}
        else
          [o | open] = open
          support_loss = Map.update(support_loss, o, 1, &(&1 + 1))
          {open, drops} =
            if support_loss[o] < on_count[o], do: {open, drops},
            else: {open ++ nxt_open.(o), drops + 1}
          {:cont, {open, support_loss, drops}}
        end
      end) |>
    then(&(if &1 == 0, do: {safe + 1, drops}, else: {safe, drops + &1}))
  end)

IO.puts("Part 1: #{pt1}")
IO.puts("Part 2: #{pt2}")
