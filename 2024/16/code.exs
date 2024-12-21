# Solution to Advent of Code 2024, Day 16
# https://adventofcode.com/2024/day/16

Code.require_file("Matrix.ex", "..")
Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_input = fn lines ->
  grid = Matrix.map(lines)
  keys = Util.group_tuples(grid, 1, 0)
  [[start], [stop]] = [Map.fetch!(keys, "S"), Map.fetch!(keys, "E")]
  %{grid: grid, pos: start, goal: stop, dir: :e, score: 0,
    visited: MapSet.new([start])}
end

next_dirs = fn dir ->
  all = %{e: :w, w: :e, n: :s, s: :n}
  opp = Map.fetch!(all, dir)
  Map.keys(all) |> Map.new(&{&1, 1001}) |> Map.delete(opp) |> Map.put(dir, 1)
end

dir_pos = fn pos -> Enum.zip(~w(w e n s)a, Util.adj_pos(pos)) |> Map.new end

possible_moves = fn data ->
  [nxt, n_p] = [next_dirs.(data.dir), dir_pos.(data.pos)]
  Enum.map(nxt, fn {d, v} -> {Map.get(n_p, d), d, v + data.score} end) |>
  Enum.reject(fn {p, _, _} -> Map.fetch!(data.grid, p) == "#" end) |>
  Enum.reject(fn {p, _, _} -> MapSet.member?(data.visited, p) end) |>
  Enum.map(fn {p, d, s} ->
    %{data | pos: p, dir: d, score: s, visited: MapSet.put(data.visited, p)}
  end)
end

next_step = fn opts ->
  [data | opts] = opts
  if data.pos == data.goal do {data, opts}
  else
    nxt = possible_moves.(data)
    Enum.group_by(nxt ++ opts, &{&1.pos, &1.dir}) |> Map.values |>
    Enum.map(fn list ->
      if length(list) == 1 do hd(list)  # this saves a few seconds
      else
        min_score = Enum.min_by(list, & &1.score).score
        Enum.filter(list, & &1.score == min_score) |>
        Enum.reduce(nil, fn d1, d2 ->
          if is_nil(d2), do: d1,
          else: %{d1 | visited: MapSet.union(d1.visited, d2.visited)}
        end)
      end
    end) |> Enum.sort_by(& &1.score)
  end
end

solve = fn data ->
  Enum.reduce_while(Stream.iterate(1, &(&1 + 1)), {[data], nil, nil},
    fn t, {opts, best, visited} ->
      if Integer.mod(t, 10000) == 0, do: IO.puts("Steps: #{t}")
      if Enum.empty?(opts) do {:halt, {best, MapSet.size(visited)}}
      else
        nxt = next_step.(opts)
        if is_tuple(nxt) do
          {data, nxt} = nxt
          cond do
            is_nil(best) -> {:cont, {nxt, data.score, data.visited}}
            data.score > best -> {:halt, {best, MapSet.size(visited)}}
            true -> {:cont, {nxt, best, MapSet.union(visited, data.visited)}}
          end
        else
          if is_nil(best), do: {:cont, {nxt, best, visited}},
          else: {:cont, {Enum.reject(nxt, & &1.score > best), best, visited}}
        end
      end
    end)
end

{pt1, pt2} = read_input.() |> parse_input.() |> solve.()

IO.puts("\nPart 1: #{pt1}\nPart 2: #{pt2}")

# elapsed time: approx. 135 sec for both parts together
# (I know this could be faster, but I've run out of patience with it)
