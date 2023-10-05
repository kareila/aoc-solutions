# Solution to Advent of Code 2020, Day 4
# https://adventofcode.com/2020/day/4

# returns a list of non-blank BLOCKS from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n\n", trim: true)
end

parse_block = fn block ->
  String.split(block) |> Enum.map(&String.split(&1, ":")) |>
  Map.new(fn [k, v] -> {String.to_atom(k), v} end)
end

# these are the only fields we check - anything else is ignored
req_fields = ~w(byr iyr eyr hgt hcl ecl pid)a

check_record = fn r, valid? ->
  Enum.all?(req_fields, fn f ->
    if Map.has_key?(r, f), do: valid?.(f, r[f]), else: false
  end)
end

all_valid = fn _, _ -> true end

data = read_input.() |> Enum.map(parse_block)

result = fn valid? -> Enum.count(data, &check_record.(&1, valid?)) end

IO.puts("Part 1: #{result.(all_valid)}")


check_num = fn n, n_min, n_max ->
  val = String.to_integer(n)
  is_integer(val) and val >= n_min and val <= n_max
end

check_height = fn val ->
  chk = Regex.run(~r/^(\d+)(cm|in)$/, val)
  if is_nil(chk) do false
  else
    [_, n, v] = chk
    case v do
      "cm" -> check_num.(n, 150, 193)
      "in" -> check_num.(n, 59, 76)
    end
  end
end

validate = fn field, val ->
  case field do
    :byr -> check_num.(val, 1920, 2002)
    :iyr -> check_num.(val, 2010, 2020)
    :eyr -> check_num.(val, 2020, 2030)
    :hgt -> check_height.(val)
    :hcl -> Regex.match?(~r/^#[0-9a-f]{6}$/, val)
    :ecl -> val in ~w[amb blu brn gry grn hzl oth]s
    :pid -> Regex.match?(~r/^\d{9}$/, val)
  end
end

IO.puts("Part 2: #{result.(validate)}")
