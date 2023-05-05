# Solution to Advent of Code 2022, Day 7
# https://adventofcode.com/2022/day/7

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

# Need to parse lines as a nested file structure.
init_data = fn -> %{ curdir: "/", tree: %{}, orgdirs: %{} } end

chdir = fn newdir, data ->
  tree = Map.put_new(data.tree, newdir, [0])  # size is first array element
  depth = Regex.scan(~r"/", newdir) |> Enum.count
  d_dirs = Map.get(data.orgdirs, depth, MapSet.new) |> MapSet.put(newdir)
  %{curdir: newdir, tree: tree, orgdirs: Map.put(data.orgdirs, depth, d_dirs)}
end

append_tree = fn d, data ->
  %{data | tree: Map.put(data.tree, data.curdir, d)}
end

parse_lines = fn lines ->
  Enum.reduce(lines, init_data.(), fn l, data ->
    path = fn dir -> "#{data.curdir <> dir}/" end
    cond do
      l == "$ ls" -> data  # list contents, no-op
      l == "$ cd /" -> chdir.("/", data)  # change to root directory
      l == "$ cd .." ->  # change to parent directory,  e.g. /a/b/c/ -> /a/b/
            Regex.replace(~r"[^/]+\/$", data.curdir, "") |>  chdir.(data)
      String.starts_with?(l, "$ cd ") ->  # change to subdirectory
            [_, newdir] = Regex.run(~r"^\$ cd (.+)$", l)
            path.(newdir) |> chdir.(data)
      String.starts_with?(l, "dir ") ->  # subdirectory name
            [_, subdir] = Regex.run(~r"^dir (.+)$", l)
            [d_sz | dirs] = data.tree[data.curdir]
            [d_sz | [path.(subdir) | dirs]] |> append_tree.(data)
      true ->  # directory contains a file, just count the size
            [_, sz] = Regex.run(~r"^(\d+) ", l)
            [d_sz | dirs] = data.tree[data.curdir]
            [d_sz + String.to_integer(sz) | dirs] |> append_tree.(data)
    end
  end)
end

# Need to propagate the file sizes from the bottom up.
find_size = fn dir, tree ->
  [d_sz | subdirs] = tree[dir]  # directory contents
  sizes = Map.take(tree, subdirs) |> Map.values
  if Enum.any?(sizes, &is_list/1), do: raise(RuntimeError, "out of order"),
  else: Enum.sum([d_sz | sizes])
end

get_sizes = fn data ->
  Map.to_list(data.orgdirs) |>
  List.keysort(0, :desc) |>  # sort by depth, deepest first
  Enum.flat_map(&elem(&1,1)) |>  # sorted list of directories
  Enum.reduce(data.tree, fn d, tree ->
    Map.put(tree, d, find_size.(d, tree))
  end) |> Map.values
end

sizes = read_input.() |> parse_lines.() |> get_sizes.()

# Find all of the directories with a total size of at most 100000.
under_limit = Enum.filter(sizes, &(&1 <= 100_000))

IO.puts("Part 1: #{Enum.sum(under_limit)}")


# Find the smallest directory that, if deleted, would free up enough space.
current_freespace = 70_000_000 - Enum.max(sizes)  # max is size of /
amount_to_delete = 30_000_000 - current_freespace

candidates = Enum.filter(sizes, &(&1 >= amount_to_delete))

IO.puts("Part 2: #{Enum.min(candidates)}")
