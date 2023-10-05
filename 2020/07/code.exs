# Solution to Advent of Code 2020, Day 7
# https://adventofcode.com/2020/day/7

Code.require_file("Recurse.ex", ".")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_line = fn line ->
  [_, type, c] = Regex.run(~r/^(\w+ \w+) bags contain ([^.]+)\.$/, line)
  c = String.split(c, ", ")
  contents =
    if hd(c) == "no other bags" do nil
    else
      Map.new(c, fn b ->
        [_, num, color] = Regex.run(~r/^(\d+) (\w+ \w+) bags?$/, b)
        {color, String.to_integer(num)}
      end)
    end
  {type, contents}
end

rules = read_input.() |> Map.new(parse_line)

data = Map.keys(rules) |> Enum.reduce(%{}, &Recurse.unpack(&1, &2, rules))

pt1 = Map.values(data) |> Enum.count(&Map.has_key?(&1, "shiny gold"))

IO.puts("Part 1: #{pt1}")


pt2 = Map.fetch!(data, "shiny gold") |> Map.values |> Enum.sum

IO.puts("Part 2: #{pt2}")
