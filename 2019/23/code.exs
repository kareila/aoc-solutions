# Solution to Advent of Code 2019, Day 23
# https://adventofcode.com/2019/day/23

require Intcode  # for prog_step()

# returns a list of non-blank lines from the input file
read_input = fn ->
  filename = "input.txt"
  File.read!(filename) |> String.split("\n", trim: true)
end

parse_input = fn line ->
  String.split(line, ",") |> Enum.map(&String.to_integer/1)
end

data = read_input.() |> hd |> parse_input.()

indices! = Range.to_list(0..49)

# note: I tried changing this from a list to a map but it wasn't faster
# I suspect the speed is bottlenecked by the size of the data list
init_network = for addr <- indices!, into: [], do:
  %{pos: 0, nums: data, output: [], r_base: 0,
    input: [addr], halted: false, idle_count: 0}

# The network itself also has a state - in addition to the list of addresses,
# it also needs to intercept anything sent to the special 255 address (NAT).

update_input = fn addresses, addr, packet ->
  append_packet = fn v -> v ++ packet end
  List.update_at(addresses, addr, &Map.update!(&1, :input, append_packet))
end

transmit_packet = fn [addr | packet], network ->
  if addr == 255 do
    %{network | idle: false, nat: [packet | network.nat]}
  else
    addresses = update_input.(network.addresses, addr, packet)
    %{network | idle: false, addresses: addresses}
  end
end

# advance each computer's state one step at a time
step_program = fn state ->
  [input | queue] = if length(state.input) > 0, do: state.input, else: [-1]
  {opcode, state} = if state.halted, do: {99, state},
                    else: Intcode.prog_step(input, state)
  idle_count = if input == -1, do: state.idle_count + 1, else: 0
  case opcode do
    3  -> %{state | idle_count: idle_count, input: queue}
    4  -> %{state | idle_count: 0}
    99 -> %{state | halted: true}
    _ -> state
  end
end

update_state = fn network, addr, state ->
  %{network | addresses: List.replace_at(network.addresses, addr, state)}
end

step_network = fn network ->
  Enum.reduce(indices!, network, fn addr, network ->
    state = Enum.at(network.addresses, addr) |> step_program.()
    if length(state.output) < 3 do
      update_state.(network, addr, state)
    else
      transmit_packet.(state.output, network) |>
      update_state.(addr, %{state | output: []})
    end
  end)
end

network_all? = fn n, state_check -> Enum.all?(n.addresses, state_check) end

repeated? = fn s -> length(s) > 1 and Enum.at(s, 0) == Enum.at(s, 1) end

run_network = fn ->
  network = %{addresses: init_network, nat: [], sent_y: [],
              nat_used: false, idle: false}
  Enum.reduce_while(Stream.cycle([1]), network, fn _, network ->
    network = step_network.(network)
    has_nat? = length(network.nat) > 0
    cond do
      # halting was unneeded but I felt better about having it
      network_all?.(network, &(&1.halted)) -> raise(RuntimeError)
      has_nat? and not network.nat_used ->
        IO.puts("Part 1: #{network.nat |> List.last |> List.last}")
        {:cont, %{network | nat_used: true}}
      repeated?.(network.sent_y) -> {:halt, hd(network.sent_y)}
      # nat needs to be blanked on send for this to work properly,
      # although I didn't find that to be clear from the instructions
      has_nat? and network_all?.(network, &(&1.idle_count > 1)) ->
        if network.idle do
          [x, y] = hd(network.nat)
          network = transmit_packet.([0, x, y], network)
          {:cont, %{network | sent_y: [y | network.sent_y], nat: []}}
        else
          {:cont, %{network | idle: true}}
        end
      true -> {:cont, network}
    end
  end)
end

IO.puts("Part 2: #{run_network.()}")

# elapsed time: approx. 28 sec
