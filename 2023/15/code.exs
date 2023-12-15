# Solution to Advent of Code 2023, Day 15
# https://adventofcode.com/2023/day/15

# ONE COMMA-SEPARATED STRING, IGNORE NEWLINES
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.replace("\n", "") |> String.split(",")
end

data = read_input.()

hash_string = fn str ->
  Enum.reduce(String.to_charlist(str), 0, fn c, tot ->
    rem((tot + c) * 17, 256)
  end)
end

IO.puts("Part 1: #{Enum.map(data, hash_string) |> Enum.sum}")


do_dash = fn lens, boxes ->
  box = hash_string.(lens)
  curr = Map.get(boxes, box, [])
  removed = List.keydelete(curr, lens, 0)
  Map.put(boxes, box, removed)
end

do_equals = fn [lens, f], boxes ->
  box = hash_string.(lens)
  curr = Map.get(boxes, box, [])
  replaced = if List.keymember?(curr, lens, 0),
             do: List.keyreplace(curr, lens, 0, {lens, f}),
             else: [{lens, f} | curr]
  Map.put(boxes, box, replaced)
end

do_step = fn str, boxes ->
  if String.ends_with?(str, "-"),
  do: String.trim_trailing(str, "-") |> do_dash.(boxes),
  else: String.split(str, "=") |> do_equals.(boxes)
end

focus_power = fn {box, lenses} ->
  Enum.reverse(lenses) |> Enum.with_index(1) |>
  Enum.map(fn {{_, f}, slot} ->
    [box + 1, slot, String.to_integer(f)] |> Enum.product
  end)
end

data = Enum.reduce(data, %{}, do_step)

IO.puts("Part 2: #{Enum.flat_map(data, focus_power) |> Enum.sum}")
