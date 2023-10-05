# Solution to Advent of Code 2020, Day 21
# https://adventofcode.com/2020/day/21

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_line = fn line ->
  [item_str, a_str] = String.split(line, " (contains ")
  allergens = String.trim_trailing(a_str, ")") |> String.split(", ")
  %{items: String.split(item_str), allergens: allergens}
end

parse_input = fn input ->
  Enum.reduce(input, {MapSet.new, %{}, []},
  fn line, {foods, allergens, recipes} ->
    %{items: i, allergens: a} = parse_line.(line)
    allergens = Enum.reduce(a, allergens, fn a, allergens ->
      Map.update(allergens, a, [i], &[i | &1]) end)
    {MapSet.new(i) |> MapSet.union(foods), allergens, [i | recipes]}
  end)
end

{foods, allergens, recipes} = read_input.() |> parse_input.()

# Anything missing from a specific recipe cannot possibly
# contain any of the allergens listed in that recipe.
eliminated =
  Enum.reduce(allergens, %{}, fn {a, recipes}, e ->
    eliminated = Map.put_new(e, a, MapSet.new)
    Enum.reduce(recipes, eliminated, fn items, e ->
      MapSet.difference(foods, MapSet.new(items)) |>
      MapSet.union(e[a]) |> then(&Map.put(e, a, &1))
    end)
  end) |> Map.values

# Which ingredients are in every "eliminated" group?
safe =
  Enum.reduce(foods, MapSet.new, fn food, safe ->
    if Enum.all?(eliminated, fn group -> food in group end),
    do: MapSet.put(safe, food), else: safe
  end) |> MapSet.to_list

food_counts = fn recipes -> List.flatten(recipes) |> Enum.frequencies end

count_safe = Map.take(food_counts.(recipes), safe) |> Map.values |> Enum.sum

IO.puts("Part 1: #{count_safe}")


# Which remaining foods are in EVERY recipe containing a specific allergen?
possible =
  Map.new(allergens, fn {a, recipes} ->
    Map.drop(food_counts.(recipes), safe) |>
    Map.filter(fn {_, v} -> v == length(recipes) end) |>
    Map.keys |> then(&{a, &1})
  end)

definite =
  Enum.reduce_while(possible, {%{}, possible}, fn _, {definite, possible} ->
    {singles, possible} =
      Enum.split_with(possible, fn {_, v} -> length(v) == 1 end)
    if Enum.empty?(singles) do {:halt, definite}
    else
      Enum.reduce(singles, {definite, possible}, fn {a, [v]}, {d, p} ->
        possible = Map.new(p, fn {a, vs} -> {a, List.delete(vs, v)} end)
       {Map.put(d, a, v), Map.delete(possible, a)} 
      end) |> then(&{:cont, &1})
    end
  end) |> Enum.sort |> Enum.map_join(",", &elem(&1,1))

IO.puts("Part 2: #{definite}")
