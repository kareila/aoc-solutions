# Solution to Advent of Code 2020, Day 16
# https://adventofcode.com/2020/day/16

Code.require_file("Matrix.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_nums = fn str, c ->
  String.split(str, c) |> Enum.map(&String.to_integer/1)
end

parse_range = fn r -> parse_nums.(r, "-") end
parse_ticket = fn t -> parse_nums.(t, ",") end

parse_rule = fn str ->
  [k, v] = String.split(str, ": ")
  {k, String.split(v, " or ") |> Enum.flat_map(parse_range)}
end

parse_input = fn lines ->
  {tickets, rules} = Enum.split_with(lines, &String.contains?(&1, ","))
  [mine | tickets] = Enum.map(tickets, parse_ticket)
  rules = Enum.reject(rules, &String.ends_with?(&1, ":"))
  %{rules: Map.new(rules, parse_rule), tickets: tickets, mine: mine}
end

data = read_input.() |> parse_input.()

in_range? = fn [n1, n2, n3, n4], t -> t in n1..n2 or t in n3..n4 end

is_valid? = fn t ->
  Enum.any?(data.rules, fn {_, r} -> in_range?.(r, t) end)
end

{valid, invalid} =
  Enum.split_with(data.tickets, fn t -> Enum.all?(t, is_valid?) end)

error_rate = List.flatten(invalid) |> Enum.reject(is_valid?) |> Enum.sum

IO.puts("Part 1: #{error_rate}")


fields = Matrix.transpose(valid) |> Enum.with_index

check_fields = fn rules ->
  Enum.map(fields, fn {nums, i} ->
    Enum.flat_map(rules, fn {f, r} ->
      if Enum.all?(nums, &in_range?.(r, &1)), do: [{f, i}], else: []
    end)
  end) |> Enum.group_by(&length/1)
end

create_field_map = fn ->
  Enum.reduce_while(Stream.cycle([1]), {%{}, data.rules},
  fn _, {found, search} ->
    if Enum.empty?(search) do {:halt, found}
    else
      Map.fetch!(check_fields.(search), 1) |> List.flatten |>
      Enum.reduce({found, search}, fn {k, v}, {found, search} ->
        {Map.put(found, k, v), Map.delete(search, k)}
      end) |> then(&{:cont, &1})
    end
  end)
end

departures = create_field_map.() |>
  Map.filter(fn {k, _} -> Regex.match?(~r/^departure /, k) end) |>
  Map.values |> Enum.map(&Enum.at(data.mine, &1)) |> Enum.product

IO.puts("Part 2: #{departures}")
