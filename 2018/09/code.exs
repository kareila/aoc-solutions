# Solution to Advent of Code 2018, Day 9
# https://adventofcode.com/2018/day/9

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_input = fn line ->
  [_, players, marbles] = Regex.run(~r/(\d+)\D+(\d+)/, line)
  tree = %{0 => %{val: 0, next: 0, prev: 0}}
  %{players: String.to_integer(players), cur: 1, scores: %{},
    marbles: String.to_integer(marbles), pos: 0, circle: tree}
end

score_game = fn data -> Map.values(data.scores) |> Enum.max end

circle_delete = fn pos, circle ->
  %{prev: prev_i, next: next_i} = circle[pos]
  prev = %{circle[prev_i] | next: next_i}
  next = %{circle[next_i] | prev: prev_i}
  Map.merge(circle, %{prev_i => prev, next_i => next}) |> Map.delete(pos)
end

circle_insert = fn val, pos, circle ->
  prev = circle[pos]
  next = circle[prev.next]
  this = %{val: val, next: next.val, prev: prev.val}
  if prev.val == next.val do
    Map.merge(circle, %{this.val => this, prev.val => %{prev | prev: val, next: val}})
  else
    prev = %{prev | next: this.val}
    next = %{next | prev: this.val}
    Map.merge(circle, %{this.val => this, prev.val => prev, next.val => next})
  end
end

play_game = fn data ->
  Enum.reduce(1..data.marbles, data, fn mval, data ->
    nextp = if data.cur == data.players, do: 1, else: data.cur + 1
    if Integer.mod(mval, 23) == 0 do
      newpos = Enum.reduce(1..7, data.pos, fn _, pos -> data.circle[pos].prev end)
      pnode = data.circle[newpos]
      score = mval + pnode.val
      scores = Map.update(data.scores, data.cur, score, &(&1 + score))
      circle = circle_delete.(newpos, data.circle)
      %{data | scores: scores, cur: nextp, circle: circle, pos: pnode.next}
    else
      newpos = data.circle[data.pos].next
      circle = circle_insert.(mval, newpos, data.circle)
      %{data | cur: nextp, circle: circle, pos: circle[newpos].next}
    end
  end)
end

data = read_input.() |> hd |> parse_input.()

IO.puts("Part 1: #{play_game.(data) |> score_game.()}")


data = %{data | marbles: data.marbles * 100}

IO.puts("Part 2: #{play_game.(data) |> score_game.()}")

# elapsed time: approx. 15 sec for both parts together
