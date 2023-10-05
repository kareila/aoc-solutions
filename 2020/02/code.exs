# Solution to Advent of Code 2020, Day 2
# https://adventofcode.com/2020/day/2

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_line = fn line ->
  [_, cmin, cmax, chr, pw] = Regex.run(~r/^(\d+)-(\d+) ([^:]): (\w+)/, line)
  [cmin, cmax] = Enum.map([cmin, cmax], &String.to_integer/1)
  %{cmin: cmin, cmax: cmax, chr: chr, pw: pw}
end

data = read_input.() |> Enum.map(parse_line)

check1 = fn line ->
  pwc = String.graphemes(line.pw)
  num = Enum.count(pwc, &(&1 == line.chr))
  num >= line.cmin and num <= line.cmax
end

IO.puts("Part 1: #{Enum.count(data, check1)}")


check2 = fn line ->
  [p1, p2] = [line.cmin - 1, line.cmax - 1]
  [c1, c2] = [String.at(line.pw, p1), String.at(line.pw, p2)]
  Enum.count([c1, c2], &(&1 == line.chr)) == 1
end

IO.puts("Part 2: #{Enum.count(data, check2)}")
