defmodule ExNat.Forwarder do
  use GenServer

  def child_spec(opts) do
    interface = Keyword.fetch!(opts, :interface)
    to_ip = Keyword.fetch!(opts, :to_ip)
    to_port = Keyword.fetch!(opts, :to_port)

    %{
      id: module_name(to_ip, to_port),
      start: {__MODULE__, :start_link, [[interface, to_ip, to_port]]}
    }
  end

  def send(nat_info, to_ip, to_port) do
    name = module_name(to_ip, to_port)
    GenServer.cast(name, {:send, nat_info})
  end

  def start_link(opts = [_interface, to_ip, to_port]) do
    GenServer.start_link(__MODULE__, opts, name: module_name(to_ip, to_port))
  end

  def init([interface, to_ip, to_port]) do
    {:ok, ref} = :epcap.start_link([{:inteface, interface}])
    {:ok, %{ref: ref, interface: interface, to_ip: to_ip, to_port: to_port}}
  end

  def handle_info(
        {:packet, _dlt, _time, _length, _bin_payload},
        data
      ) do
    {:noreply, data}
  end

  def handle_cast({:send, nat_info}, data = %{interface: interface, ref: ref}) do
    IO.puts("forward on interface #{interface}")
    :epcap.send(ref, nat_info.packet)
    {:noreply, data}
  end

  defp module_name(to_ip, to_port) do
    Module.concat([__MODULE__, "#{inspect(to_ip)}", "#{inspect(to_port)}"])
  end
end
