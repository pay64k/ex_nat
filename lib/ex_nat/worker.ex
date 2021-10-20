defmodule ExNat.Worker do
  use GenServer

  alias ExNat.NatInfo

  # packet should have ipv4 and tcp/udp headers
  @required_headers_amount 2

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    interface = Keyword.fetch!(opts, :interface)
    transport = Keyword.fetch!(opts, :transport)
    {:ok, ref} = :epcap.start_link([{:inteface, interface}])
    {:ok, %{ref: ref, interface: interface, transport: transport}}
  end

  def handle_info(
        {:packet, _dlt, _time = {_, _, _}, _length, bin_payload},
        data = %{transport: transport}
      ) do
    headers =
      bin_payload
      |> decode()
      |> get_headers([:ipv4, transport])

    case headers do
      :ignore ->
        {:noreply, data}

      headers ->
        nat_info =
          Enum.reduce(headers, %NatInfo{}, fn header, nat_info ->
            type = elem(header, 0)
            data_from_header(type, header, nat_info)
          end)
          |> IO.inspect()

        {:noreply, data}
    end
  end

  defp decode(bin_payload) do
    {:ok, {headers, _payload}} = :pkt.decode(bin_payload)
    headers
  end

  defp get_headers(headers, types) do
    headers =
      Enum.filter(headers, fn tuple ->
        elem(tuple, 0) in types
      end)

    if Enum.count(headers) < @required_headers_amount,
      do: :ignore,
      else: headers
  end

  defp data_from_header(:ipv4, header, nat_info) do
    # https://github.com/msantos/pkt/blob/master/include/pkt_ipv4.hrl
    {:ipv4, _, _, _, _, _, _, _, _, _, _, _, from_ip, to_ip, _} = header

    %{nat_info | from_ip: from_ip, to_ip: to_ip}
  end

  defp data_from_header(:tcp, header, nat_info) do
    # https://github.com/msantos/pkt/blob/master/include/pkt_tcp.hrl
    {:tcp, from_port, to_port, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _} = header

    %{nat_info | from_port: from_port, to_port: to_port}
  end
end
