# Solution to Advent of Code 2020, Day 12
# https://adventofcode.com/2020/day/12

Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_line = fn line ->
  {op, n} = String.split_at(line, 1)
  {op, String.to_integer(n)}
end

data = read_input.() |> Enum.map(parse_line)

init_state = %{pos: {0, 0}, facing: 0}

do_instruction = fn {op, num}, %{pos: {x, y}, facing: facing} ->
  dirs = [{num, 0}, {0, -num}, {-num, 0}, {0, num}]
  {dx, dy} =
    if op == "F" do
      [0, 90, 180, 270] |> Enum.zip(dirs) |> Map.new |> Map.fetch!(facing)
    else
      ~w(E S W N)s |> Enum.zip(dirs) |> Map.new |> Map.get(op, {0,0})
    end
  facing =
    case op do
      "L" -> rem(facing - num + 360, 360)
      "R" -> rem(facing + num, 360)
      _ -> facing
    end
  %{pos: {x + dx, y + dy}, facing: facing}
end

navigate = fn state, do_fn ->
  Enum.reduce(data, state, do_fn).pos |> Util.m_dist({0,0})
end

IO.puts("Part 1: #{navigate.(init_state, do_instruction)}")


init_state = %{wpt: {10, 1}, pos: {0, 0}}

do_instruction = fn {op, num}, %{pos: {px, py}, wpt: {wx, wy}} ->
  dirs = [{num, 0}, {0, -num}, {-num, 0}, {0, num}]
  {dx, dy} = ~w(E S W N)s |> Enum.zip(dirs) |> Map.new |> Map.get(op, {0,0})
  {wx, wy} = {wx + dx, wy + dy}
  {dx, dy} = if op == "F", do: {wx * num, wy * num}, else: {0,0}
  {px, py} = {px + dx, py + dy}
  {wx, wy} =
    case op do
      "L" -> Enum.zip([90, 180, 270], [{-wy, wx}, {-wx, -wy}, {wy, -wx}])
      "R" -> Enum.zip([270, 180, 90], [{-wy, wx}, {-wx, -wy}, {wy, -wx}])
      _ -> []
    end |> Map.new |> Map.get(num, {wx, wy})
  %{pos: {px, py}, wpt: {wx, wy}}
end

IO.puts("Part 2: #{navigate.(init_state, do_instruction)}")
