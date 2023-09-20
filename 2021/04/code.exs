# Solution to Advent of Code 2021, Day 4
# https://adventofcode.com/2021/day/4

# returns a list of ALL BLOCKS from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n\n", trim: true)
end

parse_board = fn grid ->
  for {row, y} <- Enum.with_index(grid), {v, x} <- Enum.with_index(row),
  do: {x, y, v}
end

parse_lines = fn lines ->
  Enum.map(lines, fn block ->
    String.split(block, "\n", trim: true) |>
    Enum.map(fn line ->
      String.split(line, " ", trim: true) |> Enum.map(&String.to_integer/1)
    end)
  end) |> Enum.map(parse_board)
end

parse_input = fn [draws | lines] ->
  draws = String.split(draws, ",") |> Enum.map(&String.to_integer/1)
  %{draws: draws, boards: parse_lines.(lines)}
end

data = read_input.() |> parse_input.()

has_elem_bingo? = fn board, draws, e ->
  Enum.group_by(board, &elem(&1,e), &elem(&1,2)) |> Map.values |>
  Enum.any?(&MapSet.subset?(MapSet.new(&1), draws))
end

has_bingo? = fn board, draws ->
  has_elem_bingo?.(board, draws, 0) or has_elem_bingo?.(board, draws, 1)
end

find_first_bingo = fn ->
  Enum.reduce_while(data.draws, MapSet.new, fn d, called ->
    called = MapSet.put(called, d)
    bingo = Enum.find(data.boards, &has_bingo?.(&1, called))
    if bingo, do: {:halt, [bingo, d, called]}, else: {:cont, called}
  end)
end

calc_score = fn [board, b_num, called] ->
  Enum.map(board, &elem(&1,2)) |> Enum.reject(&MapSet.member?(called, &1)) |>
  Enum.sum |> then(&(&1 * b_num))
end

IO.puts("Part 1: #{find_first_bingo.() |> calc_score.()}")


find_last_bingo = fn ->
  Enum.reduce_while(data.draws, {data.boards, MapSet.new},
  fn d, {boards, called} ->
    called = MapSet.put(called, d)
    {bingo, boards} = Enum.split_with(boards, &has_bingo?.(&1, called))
    if Enum.empty?(boards), do: {:halt, [hd(bingo), d, called]},
    else: {:cont, {boards, called}}
  end)
end

IO.puts("Part 2: #{find_last_bingo.() |> calc_score.()}")
