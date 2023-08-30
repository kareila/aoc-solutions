# Solution to Advent of Code 2019, Day 22
# https://adventofcode.com/2019/day/22

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_line = fn line ->
  [_, act, params] = Regex.run(~r/^(deal|cut) (.*)$/, line)
  case act do
    "cut" -> {:cut, String.to_integer(params)}
    "deal" ->
      [_, which, arg] = Regex.run(~r/^(with|into) \S+ (\S+)$/, params)
      case which do
        "with" -> {:dealWith, String.to_integer(arg)}
        "into" -> {:dealInto, nil}
      end
    _ -> raise ArgumentError
  end
end

data = read_input.() |> Enum.map(parse_line)

# naive algorithm for shuffling the entire deck takes about 20 sec.
#
# stack_num = 10007
# init_stack = Range.to_list(0..(stack_num - 1))
#
# result_full_list = Enum.reduce(data, init_stack, fn {which, arg}, stack ->
#   case which do
#     :dealInto -> Enum.reverse(stack)
#     :dealWith ->
#       Enum.reduce(Enum.with_index(stack), init_stack, fn {v, i}, nxt ->
#         List.replace_at(nxt, Integer.mod(i * arg, stack_num), v)
#       end)
#     :cut ->
#       cut = Enum.take(stack, arg)
#       rest = Enum.drop(stack, arg)
#       if arg < 0, do: cut ++ rest, else: rest ++ cut
#     _ -> raise ArgumentError
#   end
# end) |> Enum.find_index(fn v -> v == 2019 end)
#
# Instead, let's just calculate the change in index with each technique
# for the one card whose position we care about. Relatively fast.

track_card = fn stack_size, card ->
  Enum.reduce(data, card, fn {which, arg}, idx ->
    case which do
      :dealInto -> stack_size - 1 - idx
      :dealWith -> idx * arg |> Integer.mod(stack_size)
      :cut      -> idx - arg |> Integer.mod(stack_size)
    end
  end)
end

IO.puts("Part 1: #{track_card.(10007, 2019)}")


# NOTE: Part 2 does not ask for the position of card 2019, but
# instead the value of the card that ends up in position 2020!
#
# Even with a fairly quick operation, doing it repeatedly
# 101741582076661 times will take approximately forever.
# Instead, we can think about any given arrangement of
# the stack of cards as a range, and each technique as
# a modification of the start and step of that range.
#
# Reddit solution thread that explains the math involved:
# https://www.reddit.com/r/adventofcode/comments/ee0rqi/2019_day_22_solutions/
#
# Suggested test case: num_repeats = 1, stack_size = 10007,
# card = answer from Part 1 - see if you get 2019

extended_gcd = fn n, m ->
  Enum.reduce_while(Stream.cycle([1]), {abs(n), m, 0, 1, 1, 0},
  fn _, {a, b, x, y, u, v} ->
    cond do
      a == 0 and b == 1 -> {:halt, if(n < 0, do: -x, else: x)}
      a == 0 -> raise(ArgumentError)
      true ->
        q = div(b, a)
        {:cont, {rem(b, a), a, u, v, x - u * q, y - v * q}}
    end
  end)
end

mmi = fn a, m -> rem(extended_gcd.(a, m) + m, m) end

track_repeatedly = fn stack_size, card ->
  [start_diff, step_mul] =
    Enum.reduce(data, [0, 1], fn {which, arg}, [start, step] ->
      case which do
        :dealInto -> [start - step, -step]
        :dealWith -> [start, step * mmi.(arg, stack_size)]
        :cut      -> [start + step * arg, step]
      end |> Enum.map(&Integer.mod(&1, stack_size))
    end)
  num_repeats = 101741582076661
  final_step = :crypto.mod_pow(step_mul, num_repeats, stack_size)
            |> :binary.decode_unsigned
  final_start = start_diff * (1 - final_step) * mmi.(1 - step_mul, stack_size)
  Integer.mod(final_start + final_step * card, stack_size)
end

IO.puts("Part 2: #{track_repeatedly.(119315717514047, 2020)}")
