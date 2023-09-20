# Solution to Advent of Code 2021, Day 23
# https://adventofcode.com/2021/day/23

require Recurse  # for solve()

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

all_matches = fn str, pat ->
  Regex.scan(pat, str, capture: :all_but_first) |> Enum.concat
end

# translate occupant values to numerics, which also correspond
# to the power of ten that it costs for them to move one step
occ_num = fn c ->
  String.graphemes("ABCD") |> Enum.find_index(&(&1 == c))
end

init_rooms = fn lines ->
  Enum.flat_map(lines, &all_matches.(&1, ~r/([ABCD])/)) |>
  Enum.chunk_every(4) |>
  Enum.reduce([[], [], [], []], fn occ, start_rooms ->
    Enum.zip_with(occ, start_rooms, fn c, s -> s ++ [occ_num.(c)] end)
  end)
end

#     hallway spots:  0 | 1 | 2 | 3 | 4 | 5 | 6
#                           ^   ^   ^   ^
#     rooms:                0   1   2   3

init_hallway = fn rooms ->
  room_size = length(hd(rooms))
  # for each of the four rooms, we need the number of steps to each hall spot
  [steps_0, steps_1] = [[ 2, 1, 1, 3, 5, 7, 8 ], [ 4, 3, 1, 1, 3, 5, 6 ]]
  [steps_2, steps_3] = [Enum.reverse(steps_1), Enum.reverse(steps_0)]
  %{rooms: rooms, room_size: room_size, hallway: List.duplicate(nil, 7),
    hall_costs: %{0 => steps_0, 1 => steps_1, 2 => steps_2, 3 => steps_3},
    ckey: fn data ->  # generate static state key for cache use
      Enum.map_join(data.rooms, "|", &Enum.join(&1, ".")) <> "|" <>
      Enum.map_join(data.hallway, "-", &(&1 || "_"))
    end,
    done: fn data ->  # Is everyone where they belong?
      Enum.with_index(data.rooms) |>
      Enum.all?(fn {r, i} ->
        length(r) == data.room_size and Enum.all?(r, &(&1 == i))
      end)
    end}
end

room = fn data, i -> Enum.at(data.rooms, i) end

move_cost = fn data, ri, hi, to_room? ->
  # if to_room? is true, omit this target's current position at hallway[hi]
  h_occ = if to_room?, do: 1, else: 0
  # order hallway endpoints from left to right
  [start, stop] =
    if ri + 1 < hi, do: [ri + 2, hi - h_occ], else: [hi + h_occ, ri + 1]
  # bail out if the hallway isn't clear
  if not Enum.all?(Enum.slice(data.hallway, start..stop), &is_nil/1) do nil
  else
    t = if to_room?, do: ri, else: hd(room.(data, ri))
    d = Enum.sum([Enum.at(data.hall_costs[ri], hi), h_occ,
        data.room_size - length(room.(data, ri))])
    Integer.pow(10, t) * d
  end
end

# enumerate possible room moves for every occupant of the hallway
# (will not enter the wrong room; will not enter the right room if
# it contains someone who is in the wrong place)
moves_to_room = fn data ->
  moves = Enum.with_index(data.hallway) |>
    Enum.reject(fn {h, _} -> is_nil(h) end) |>
    Enum.reject(fn {h, _} -> Enum.any?(room.(data, h), &(&1 != h)) end)
  costs = Enum.map(moves, fn {h, i} -> move_cost.(data, h, i, true) end)
  Enum.zip(moves, costs) |> Enum.reject(fn {_, c} -> is_nil(c) end) |>
  # Create a new state where this object has been moved to its room,
  # and add the state variables and cost to the list of possibilities.
  Enum.map(fn {{h, i}, c} ->
    new_rooms = List.replace_at(data.rooms, h, [h | room.(data, h)])
    new_hallway = List.replace_at(data.hallway, i, nil)
    {c, %{data | rooms: new_rooms, hallway: new_hallway}}
  end)
end

# enumerate possible hallway moves for every room
# (only the top occupant of the room can leave this turn)
moves_to_hallway = fn data ->
  moves = Enum.with_index(data.rooms) |>  # only wrong occupants will move
    Enum.filter(fn {r, ri} -> Enum.any?(r, &(&1 != ri)) end)
  for {r, ri} <- moves, {_, hi} <- Enum.with_index(data.hallway),
      cost = move_cost.(data, ri, hi, false), not is_nil(cost)
  do
    # Create a new state where this object has moved to this hallway spot,
    # and add the state variables and cost to the list of possibilities.
    {t, room} = List.pop_at(r, 0)
    new_rooms = List.replace_at(data.rooms, ri, room)
    new_hallway = List.replace_at(data.hallway, hi, t)
    {cost, %{data | rooms: new_rooms, hallway: new_hallway}}
  end
end

possible_moves = fn data ->
  # whenever we can move someone from the hallway into the room where
  # they belong, that move will always be optimal... if there are multiples,
  # only taking the first speeds things up a bit (fewer branches to try)
  r = moves_to_room.(data) |> Enum.take(1)
  if Enum.empty?(r), do: moves_to_hallway.(data), else: r
end

find_best = fn data -> Recurse.solve(data, possible_moves) |> elem(0) end

data = read_input.() |> init_rooms.() |> init_hallway.()

IO.puts("Part 1: #{find_best.(data)}")


data = read_input.() |> List.insert_at(-3, ["DCBA", "DBAC"])
    |> List.flatten |> init_rooms.() |> init_hallway.()

IO.puts("Part 2: #{find_best.(data)}")

# elapsed time: approx. 2.5 sec for both parts together
