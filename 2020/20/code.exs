# Solution to Advent of Code 2020, Day 20
# https://adventofcode.com/2020/day/20

Code.require_file("Matrix.ex", "..")
Code.require_file("Util.ex", "..")

# returns a list of non-blank BLOCKS from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n\n", trim: true)
end

parse_block = fn block ->
  [label | grid] = String.split(block, "\n", trim: true)
  [id] = Util.read_numbers(label)
  {id, Matrix.map(grid)}
end

map_edges = fn grid ->
  rows = Matrix.order_points(grid)
  cols = Matrix.transpose(rows)
  [t, b] = [List.first(rows), List.last(rows)]
  [l, r] = [List.first(cols), List.last(cols)]
  # Explanation of edge values: clockwise 1-7 odds for face up,
  # counterclockwise 2-8 evens for face down.
  [t, Enum.reverse(t), r, l, Enum.reverse(b),
   b, Enum.reverse(l), Enum.reverse(r)] |>
  Enum.map(fn list -> Enum.map_join(list, &Map.fetch!(grid, &1)) end) |>
  Enum.with_index(1) |> Map.new
end

match_edges = fn edges ->
  matches = Enum.flat_map(edges, fn {id, edge_map} ->
    Map.keys(edge_map) |> Map.from_keys(id) end) |> Util.group_tuples(0, 1)
  Enum.reduce(matches, matches, fn {k, v}, matches ->
    cond do
      not Map.has_key?(matches, k) -> matches   # already deduped
      length(v) == 1 -> Map.delete(matches, k)  # has no match
      true -> Map.delete(matches, String.reverse(k))
    end
  end) |> Map.values |>
  # Construct a map of which tiles are adjacent to a given tile.
  Enum.reduce(%{}, fn ids, adjacent ->
    Enum.reduce(ids, adjacent, fn t, adjacent ->
      adj = List.delete(ids, t) |> Enum.sort
      Map.update(adjacent, t, adj, &Enum.sort(&1 ++ adj))
    end)
  end)
end

parse_input = fn blocks ->
  tiles = Map.new(blocks, parse_block)
  edges = Map.new(tiles, fn {id, grid} -> {id, map_edges.(grid)} end)
  sz = map_size(tiles) |> :math.sqrt |> trunc
  %{tiles: tiles, edges: edges, size: sz - 1, neighbors: match_edges.(edges)}
end

find_corners = fn %{neighbors: data} ->
  Enum.group_by(data, &length(elem(&1,1)), &elem(&1,0)) |>
  Map.fetch!(2) |> Enum.sort
end

data = read_input.() |> parse_input.()

IO.puts("Part 1: #{find_corners.(data) |> Enum.product}")


init_layout = fn data ->
  [start_tile] = find_corners.(data) |> Enum.take(1)
  Map.fetch!(data.neighbors, start_tile) |> Enum.zip([{1,0}, {0,1}]) |>
  Map.new(fn {v, k} -> {k, v} end) |> Map.put({0,0}, start_tile)
end

adj_ids = fn t, layout ->
  unused = Map.drop(data.tiles, Map.values(layout)) |> Map.keys
  Map.fetch!(data.neighbors, layout[t]) |> Enum.filter(&(&1 in unused))
end

assemble_row = fn layout, data, j ->
  Enum.reduce(1..data.size, layout, fn i, layout ->
    [t1] =  # fill in the one other tile adjacent to both of these
      Enum.flat_map([{i - 1, j}, {i, j - 1}], &adj_ids.(&1, layout)) |>
      Enum.frequencies |> Map.filter(fn {_, v} -> v == 2 end) |> Map.keys
    layout = Map.put(layout, {i, j}, t1)
    if j > 1 or i == data.size do layout
    else  # special case for top edge
      [t2] = adj_ids.({i, j - 1}, layout)
      Map.put(layout, {i + 1, j - 1}, t2)
    end
  end)
end

assemble_layout = fn data ->
  Enum.reduce(1..data.size, init_layout.(data), fn j, layout ->
    layout = assemble_row.(layout, data, j)
    if j == data.size do layout
    else  # anchor the left side of the next row
      Map.put(layout, {0, j + 1}, hd(adj_ids.({0, j}, layout)))
    end
  end)
end

layout = assemble_layout.(data)

# Now comes the tricky part - filling in the tiles according to our layout.
# We have to determine the proper orientation of each tile AND make sure the
# flipped state of each tile is consistent with the ones already placed.
#
# To uniquely identify each tile's orientation, use the value of its "top".
calc_top = fn edge_val, edge_dir, ccw ->
  rotate = fn n -> rem(edge_val + n - 1, 8) + 1 end
  flip? = rem(ccw, 2) > 0
  cond do
    edge_dir == "N" -> rotate.(0)
    edge_dir == "S" -> rotate.(4)
    # Clockwise direction alternates with every tile in the grid.
    # This logic assumes that we put a clockwise tile at 0,0.
    edge_dir == "W" -> if flip?, do: rotate.(6), else: rotate.(2)
    edge_dir == "E" -> if flip?, do: rotate.(2), else: rotate.(6)
  end
end

tile_edges = fn t_id, orientation ->
  t_edges = data.edges[t_id]
  # first tile is clockwise
  t_edges = if not Enum.empty?(orientation), do: t_edges,
            else: Map.reject(t_edges, fn {_, v} -> rem(v, 2) == 0 end)
  # Gather the subset of edge matches that involve this tile.
  Enum.reduce(data.edges, %{}, fn {id, e}, t_matches ->
    Enum.reduce(e, t_matches, fn {k, v}, t_matches ->
      if not Map.has_key?(t_edges, k) do t_matches
      else
        Map.update(t_matches, k, [{id, v}], &[{id, v} | &1])
      end
    end)
  end) |> Map.values |> Enum.map(&Map.new/1)
end

tile_dirs = fn pos, o_ids ->
  Enum.reduce(Util.dir_pos(pos), %{}, fn {dir, p}, o_pos ->
    t = Map.get(layout, p)
    if is_nil(t) or t not in o_ids, do: o_pos,
    else: Map.put(o_pos, dir, t)
  end)
end

orient_tile = fn pos, orientation ->
  t_id = Map.fetch!(layout, pos)
  t_matches = tile_edges.(t_id, orientation)
  # Once at least one tile is placed, we have to maintain consistency;
  # ignore any neighboring tiles that we don't know the orientation of.
  o_ids = Enum.filter(data.neighbors[t_id], fn t ->
          Enum.empty?(orientation) or Map.has_key?(orientation, t) end)
  if Enum.empty?(o_ids), do: raise(RuntimeError, "out of bounds")
  # We need to know which of our edge values goes with which adjacent tile,
  # as well as the adjacent tile's edge value, for uniqueness purposes.
  {t_vals, o_vals} =
    Enum.reduce(t_matches, {%{}, %{}}, fn t_map, {t_vals, o_vals} ->
      o_id = Map.keys(t_map) |> List.delete(t_id) |> List.first
      cond do
        is_nil(o_id) -> {t_vals, o_vals}       # unmatched
        o_id not in o_ids -> {t_vals, o_vals}  # not in orientation
        true ->
          [t_v, o_v] = [Map.fetch!(t_map, t_id), Map.fetch!(t_map, o_id)]
          t_vals = Map.update(t_vals, o_id, [t_v], &[t_v | &1])
          o_vals = Map.update(o_vals, o_id, [o_v], &[o_v | &1])
          {t_vals, o_vals}
      end
    end)
  # Find the relative position of each tile remaining in o_ids,
  # and pick one to use to orient the current tile in the layout.
  o_pos = tile_dirs.(pos, o_ids)
  [{ov, oid}] = Enum.take(o_pos, 1)
  tv =
    if Enum.empty?(orientation) do
      # We started our initial position assuming we weren't flipped,
      # but if our edge values are running counterclockwise, we need
      # to go clockwise with the even numbers instead.
      e_side = Map.fetch!(o_pos, "E") |> then(&Map.fetch!(t_vals, &1))
      s_side = Map.fetch!(o_pos, "S") |> then(&Map.fetch!(t_vals, &1))
      if (hd(s_side) - hd(e_side)) not in [-2, 6], do: hd(t_vals[oid]),
      else: Map.fetch!(%{1 => 2, 3 => 8, 5 => 6, 7 => 4}, hd(t_vals[oid]))
    else
      same_side? = rem(hd(o_vals[oid]), 2) == rem(orientation[oid], 2)
      Enum.at(t_vals[oid], if(same_side?, do: 0, else: 1))
    end
  Map.put(orientation, t_id, calc_top.(tv, ov, Tuple.sum(pos)))
end

orientation =
  for j <- 0..data.size, i <- 0..data.size do {i, j} end |>
  Enum.reduce(%{}, orient_tile)

# After all that, we can finally start to think about drawing the image.
# The instructions say to start by removing the borders of each tile.
remove_border = fn {t_id, grid}, data ->
  {_, x_max, _, y_max} = Matrix.limits(grid)
  new_grid =
    Map.reject(grid, fn {{x, y}, _} ->
      x in [0, x_max] or y in [0, y_max] end) |>
    Map.new(fn {{x, y}, v} -> {{x - 1, y - 1}, v} end)
  %{data | tiles: Map.put(data.tiles, t_id, new_grid)}
end

data = Enum.reduce(data.tiles, data, remove_border)

# Next, we need to solve the general question of how to
# rearrange a data grid to match a specific orientation.
rotate_data = fn grid, orient, ccw ->
  vals = Enum.map(Matrix.order_points(grid), fn row ->
         Enum.map(row, &Map.fetch!(grid, &1)) end)
  ccw? = rem(ccw, 2) > 0
  case orient do
    1 when not ccw? -> vals                    # top edge, unflipped
    2 when ccw? -> vals                        # top edge, unflipped
    1 when ccw? ->                             # top edge, flipped
      Enum.map(vals, &Enum.reverse/1)
    2 when not ccw? ->                         # top edge, flipped
      Enum.map(vals, &Enum.reverse/1)
    5 when ccw? -> Enum.reverse(vals)          # bottom edge, flipped
    6 when not ccw? -> Enum.reverse(vals)      # bottom edge, flipped
    5 when not ccw? ->                         # bottom edge, unflipped
      Enum.map(vals, &Enum.reverse/1) |> Enum.reverse
    6 when ccw? ->                             # bottom edge, unflipped
      Enum.map(vals, &Enum.reverse/1) |> Enum.reverse
    4 when not ccw? -> Matrix.transpose(vals)  # left edge, flipped
    7 when ccw? -> Matrix.transpose(vals)      # left edge, flipped
    4 when ccw? ->                             # left edge, unflipped
      Enum.map(Matrix.transpose(vals), &Enum.reverse/1)
    7 when not ccw? ->                         # left edge, unflipped
      Enum.map(Matrix.transpose(vals), &Enum.reverse/1)
    3 when not ccw? ->                         # right edge, unflipped
      Enum.reverse(Matrix.transpose(vals))
    8 when ccw? ->                             # right edge, unflipped
      Enum.reverse(Matrix.transpose(vals))
    3 when ccw? ->                             # right edge, flipped
      Enum.map(Matrix.transpose(vals), &Enum.reverse/1) |> Enum.reverse
    8 when not ccw? ->                         # right edge, flipped
      Enum.map(Matrix.transpose(vals), &Enum.reverse/1) |> Enum.reverse
  end
end

# Finally, assemble the tile data onto a 2D grid, using
# our index of positions and our tile orientation data.
image_tiles =
  Enum.map(Matrix.order_points(layout), fn row ->
  Enum.map(row, &{&1, Map.fetch!(layout, &1)}) end) |>
  Enum.map(fn row -> Enum.map(row, fn {{i, j}, t_id} ->
    [grid, orient] = [data.tiles[t_id], orientation[t_id]]
    rotate_data.(grid, orient, i + j)
  end) end)

# Flatten the data into one giant tile.
image_map =
  for j <- 0..data.size, i <- 0..data.size,
      t = Enum.at(image_tiles, j) |> Enum.at(i),
      y <- 0..(length(t) - 1), x <- 0..(length(t) - 1),
      v = Enum.at(t, y) |> Enum.at(x),
      r = y + j * length(t), q = x + i * length(t), into: %{},
  do: {{q, r}, v}

# Can we look for sea monsters now?
m_tile = """
                  #
#    ##    ##    ###
 #  #  #  #  #  #
"""
o_monster = String.graphemes(m_tile) |> Enum.count(&(&1 == "#"))
o_grid = List.flatten(image_tiles) |> Enum.count(&(&1 == "#"))

search_grid = fn vals ->
  strings = Enum.map(vals, &Enum.join/1)
  monster_pat = [
    ~r/^(?:.){18}#/,
    ~r/^#(?:.){4}##(?:.){4}##(?:.){4}###/,
    ~r/^(?:.)#(?:.){2}#(?:.){2}#(?:.){2}#(?:.){2}#(?:.){2}#/,
  ] |> Enum.with_index
  [x_max, y_max] = [String.length(hd(strings)), length(strings)]
  [monster_length, monster_height] = [20, 3]
  {i_limit, j_limit} = {x_max - monster_length, y_max - monster_height}
  for j <- 0..j_limit, i <- 0..i_limit do
    Enum.all?(monster_pat, fn {pat, r} ->
      line = Enum.at(strings, j + r) |> String.slice(i, monster_length)
      Regex.match?(pat, line)
    end)
  end |> Enum.frequencies |> Map.get(true, 0)
end

rotate_search =
  Enum.map(1..8, &rotate_data.(image_map, &1, 0)) |>
  Enum.map(search_grid) |> Enum.max

roughness = o_grid - ( o_monster * rotate_search )

IO.puts("Part 2: #{roughness}")
