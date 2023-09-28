# Solution to Advent of Code 2018, Day 13
# https://adventofcode.com/2018/day/13

Code.require_file("Matrix.ex", "..")
Code.require_file("Util.ex", "..")

# NOTE: when passing in string-literal test input, escape any backslashes

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_lines = fn lines ->
  {tracks, carts} =
    Enum.reduce(Matrix.grid(lines), {%{}, %{}},
    fn {x, y, v}, {tracks, carts} ->
      cond do
        v in ["^", "v"] ->
          {Map.put(tracks, {x, y}, "|"), Map.put(carts, {x, y}, {v, 0})}
        v in ["<", ">"] ->
          {Map.put(tracks, {x, y}, "-"), Map.put(carts, {x, y}, {v, 0})}
        true ->
          {Map.put(tracks, {x, y}, v), carts}
      end
    end)
  %{tracks: tracks, carts: carts, steps: 0}
end

data = read_input.() |> parse_lines.()

lt = %{"^" => "<", "<" => "v", "v" => ">", ">" => "^"}
rt = %{"^" => ">", ">" => "v", "v" => "<", "<" => "^"}

eval_intersection = fn v, turn ->
  %{0 => {lt[v], 1}, 1 => {v, 2}, 2 => {rt[v], 0}} |> Map.fetch!(turn)
end

move_cart = fn pos, {v, turn}, tracks ->
  next_pos =
    Enum.zip(~w(< > ^ v), Util.adj_pos(pos)) |> Map.new |> Map.fetch!(v)
  case Map.fetch!(tracks, next_pos) do
    t when t in ["-", "|"] -> {next_pos, {v, turn}}
    "+" -> {next_pos, eval_intersection.(v, turn)}
    "/" when v in ["^", "v"] -> {next_pos, {rt[v], turn}}
    "/" when v in ["<", ">"] -> {next_pos, {lt[v], turn}}
    "\\" when v in ["^", "v"] -> {next_pos, {lt[v], turn}}
    "\\" when v in ["<", ">"] -> {next_pos, {rt[v], turn}}
  end
end

tick = fn data ->
  carts =
    Enum.reduce(data.carts, %{}, fn {pos, cart}, nxt ->
      # unlike more recent exercises of this type, the carts
      # don't all move simultaneously - if a cart just moved
      # into your position, you don't have a chance to evade
      if Map.has_key?(nxt, pos) do Map.put(nxt, pos, "X")
      else
        {pos, cart} = move_cart.(pos, cart, data.tracks)
        Map.put(nxt, pos, if(Map.has_key?(nxt, pos), do: "X", else: cart))
      end
    end)
  %{data | carts: carts, steps: data.steps + 1}
end

first_crash = fn data ->
  Enum.reduce_while(Stream.cycle([1]), data, fn _, data ->
    data = tick.(data)
    crashes = Map.filter(data.carts, &(elem(&1,1) == "X"))
    if Enum.empty?(crashes), do: {:cont, data},
    else: {:halt, Map.keys(crashes)}
  end) |> hd |> Tuple.to_list |> Enum.join(",")
end

IO.puts("Part 1: #{first_crash.(data)}")


crash_all = fn data ->
  Enum.reduce_while(Stream.cycle([1]), data, fn _, data ->
    data = tick.(data)
    carts = Map.filter(data.carts, &(elem(&1,1) != "X"))
    if map_size(carts) > 1, do: {:cont, %{data | carts: carts}},
    else: {:halt, Map.keys(carts)}
  end) |> hd |> Tuple.to_list |> Enum.join(",")
end

IO.puts("Part 2: #{crash_all.(data)}")


# used for inspecting track state when debugging
# print_map = fn data, fout ->
#   vcart = fn {k, v} -> {k, if(is_tuple(v), do: elem(v, 0), else: v)} end
#   view = Map.merge(data.tracks, Map.new(data.carts, vcart))
#   Matrix.print_map(view) |> then(&IO.puts(fout, &1))
#   IO.puts(fout, "\n\n\n")
# end
#
# read_input.() |> parse_lines.() |> print_map.(:stdio)
