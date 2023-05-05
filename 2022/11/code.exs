# Solution to Advent of Code 2022, Day 11
# https://adventofcode.com/2022/day/11

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# converts an input line to an integer (empty string is nil)
s_to_int = fn line ->
  if line == "", do: nil, else: String.to_integer(line)
end

# monkeys: list of maps with keys 'items', 'oper', 'test', 'true', 'false'
# inspections: number of times each monkey has inspected an item
# divisors: used for Part 2
# relief: changes in Part 2
init_data = fn fn_r ->
  %{monkeys: [], inspections: [], divisors: MapSet.new, relief: fn_r}
end

parse_items = fn [cur_m | m_list], l, data ->
  [_, item_str] = Regex.run(~r/: ([0-9, ]+)$/, l)
  items = String.split(item_str, ", ") |> Enum.map(s_to_int)
       |> Enum.reverse
  %{data | monkeys: [Map.put(cur_m, :items, items) | m_list]}
end

parse_oper = fn [cur_m | m_list], l, data ->
  [_, op, what] = Regex.run(~r/: new = old ([+*]) (\S+)$/, l)
  calc = fn arg ->
    num = if(what == "old", do: arg, else: s_to_int.(what))
    case op do
      "+" -> arg + num
      "*" -> arg * num
    end
  end
  %{data | monkeys: [Map.put(cur_m, :oper, calc) | m_list]}
end

parse_test = fn [cur_m | m_list], l, data ->
  [_, num_str] = Regex.run(~r/: divisible by (\d+)$/, l)
  num = s_to_int.(num_str)
  test = fn n -> Integer.mod(n, num) == 0 end
  %{data | monkeys: [Map.put(cur_m, :test, test) | m_list],
           divisors: MapSet.put(data.divisors, num)}
end

parse_bool = fn [cur_m | m_list], l, data, bool ->
  [_, m_id] = Regex.run(~r/: throw to monkey (\d+)$/, l)
  %{data | monkeys: [Map.put(cur_m, bool, s_to_int.(m_id)) | m_list]}
end

parse_line = fn l, data ->
  cond do
    l == "" -> data
    l =~ ~r/^Monkey / -> %{data | monkeys: [%{} | data.monkeys]}
    l =~ ~r/^\s+Starting items: / -> parse_items.(data.monkeys, l, data)
    l =~ ~r/^\s+Operation: / -> parse_oper.(data.monkeys, l, data)
    l =~ ~r/^\s+Test: / -> parse_test.(data.monkeys, l, data)
    l =~ ~r/^\s+If true: / -> parse_bool.(data.monkeys, l, data, :true)
    l =~ ~r/^\s+If false: / -> parse_bool.(data.monkeys, l, data, :false)
  end
end

parse_lines = fn input, relief ->
  data = Enum.reduce(input, init_data.(relief), parse_line)
  inspections = List.duplicate(0, length(data.monkeys))
  %{data | monkeys: Enum.reverse(data.monkeys), inspections: inspections}
end

# On a single monkey's turn, it inspects and throws all of the
# items it is holding one at a time and in the order listed.

per_item = fn {item, cur_m}, data ->
  item = cur_m.oper.(item) |> data.relief.()
  next_i = if(cur_m.test.(item), do: cur_m.true, else: cur_m.false)
  next_m = Enum.at(data.monkeys, next_i)
  next_m = %{next_m | items: [item | next_m.items]}
  %{data | monkeys: List.replace_at(data.monkeys, next_i, next_m)}
end

m_turn = fn cur_i, data ->
  cur_m = Enum.at(data.monkeys, cur_i)
  items = cur_m.items |> Enum.zip(Stream.cycle([cur_m]))
  data = Enum.reverse(items) |> Enum.reduce(data, per_item)
  cur_m = %{cur_m | items: []}  # reset
  inspected = Enum.at(data.inspections, cur_i) + length(items)
  %{data | monkeys: List.replace_at(data.monkeys, cur_i, cur_m),
           inspections: List.replace_at(data.inspections, cur_i, inspected)}
end

m_rounds = fn data, num_rounds ->
  data = Enum.reduce(1..num_rounds, data, fn _, data ->
    Enum.reduce(0..length(data.monkeys) - 1, data, m_turn)
  end)
  Enum.sort(data.inspections, :desc) |> Enum.take(2) |> Enum.product
end

m_data = read_input.() |> parse_lines.(fn num -> div(num, 3) end)

IO.puts("Part 1: #{m_rounds.(m_data, 20)}")


# Worry levels are no longer divided by three after each item is inspected.
# I struggled with this until I received some math advice: if you take the
# product of all the divisors and use it as a modulus, you can apply that to
# reduce worry levels without changing the end result of the calculations.
modulus = Enum.product(m_data.divisors)  # calculate once
relief = fn num -> Integer.mod(num, modulus) end

# full state reset
m_data = read_input.() |> parse_lines.(relief)

IO.puts("Part 2: #{m_rounds.(m_data, 10000)}")
