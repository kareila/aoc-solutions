# Solution to Advent of Code 2018, Day 25
# https://adventofcode.com/2018/day/25

Code.require_file("Util.ex", "..")

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_line = fn line -> Util.read_numbers(line) |> List.to_tuple end

find_constellation = fn [pos | data] ->
  Enum.reduce_while(Stream.cycle([1]), {data, [pos]},
  fn _, {data, found} ->
    i = Enum.reduce_while(found, nil, fn pos, _ ->
          i = Enum.find_index(data, fn p -> Util.m_dist(p, pos) <= 3 end)
          if is_nil(i), do: {:cont, i}, else: {:halt, i}
        end)
    if is_nil(i), do: {:halt, {data, found}},
    else: {:cont, {List.delete_at(data, i), [Enum.at(data, i) | found]}}
  end)
end

find_all = fn data ->
  Enum.reduce_while(Stream.cycle([1]), {data, []}, fn _, {data, all} ->
    if Enum.empty?(data) do {:halt, all}
    else
      {data, found} = find_constellation.(data)
      {:cont, {data, [found | all]}}
    end
  end)
end

constellations = read_input.() |> Enum.map(parse_line) |> find_all.()

IO.puts("Part 1: #{length(constellations)}")

# There is no Part 2!  Merry Christmas!
