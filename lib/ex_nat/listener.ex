defmodule ExNat.Listener do
  use GenServer

  alias ExNat.{NatInfo, Forwarder}

  # packet should have ipv4 and tcp/udp headers
  @required_headers_amount 2

  def child_spec(opts) do
    interface = Keyword.fetch!(opts, :interface)
    transport = Keyword.fetch!(opts, :transport)
    from_ip = Keyword.fetch!(opts, :from_ip)
    from_port = Keyword.fetch!(opts, :from_port)
    to_ip = Keyword.fetch!(opts, :to_ip)
    to_port = Keyword.fetch!(opts, :to_port)

    %{
      id: module_name(interface, transport, from_ip, from_port, to_ip, to_port),
      start:
        {__MODULE__, :start_link, [[interface, transport, from_ip, from_port, to_ip, to_port]]}
    }
  end

  # def register_forwarder(pid) do
  #   GenServer.cast
  # end

  def start_link(opts = [interface, transport, from_ip, from_port, to_ip, to_port]) do
    GenServer.start_link(__MODULE__, opts,
      name: module_name(interface, transport, from_ip, from_port, to_ip, to_port)
    )
  end

  def init([interface, transport, from_ip, from_port, to_ip, to_port]) do
    {:ok, ref} = :epcap.start_link([{:inteface, interface}])

    {:ok,
     %{
       ref: ref,
       interface: interface,
       transport: transport,
       forwarder: nil,
       from_ip: from_ip,
       from_port: from_port,
       to_ip: to_ip,
       to_port: to_port
     }}
  end

  # def handle_info(
  #       {:packet, _dlt, _time, _length, _bin_payload},
  #       data = %{forwarder: nil}
  #     ) do
  #   {:noreply, data}
  # end

  def handle_info(
        {:packet, _dlt, _time, _length, bin_payload},
        data = %{
          transport: transport,
          from_ip: from_ip,
          from_port: from_port,
          to_ip: to_ip,
          to_port: to_port
        }
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

        if nat_info.from_ip == from_ip and nat_info.from_port == from_port do
          Map.put(nat_info, :packet, bin_payload)
          |> IO.inspect()
          |> Forwarder.send(to_ip, to_port)
        end

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

    %{nat_info | from_port: from_port, to_port: to_port, transport: :tcp}
  end

  defp data_from_header(:udp, header, nat_info) do
    # https://github.com/msantos/pkt/blob/master/include/pkt_udp.hrl
    {:udp, from_port, to_port, _, _} = header

    %{nat_info | from_port: from_port, to_port: to_port, transport: :udp}
  end

  defp module_name(interface, transport, from_ip, from_port, to_ip, to_port) do
    Module.concat([
      __MODULE__,
      interface,
      "#{inspect(transport)}",
      "#{inspect(from_ip)}",
      "#{inspect(from_port)}",
      "#{inspect(to_ip)}",
      "#{inspect(to_port)}"
    ])
  end
end
