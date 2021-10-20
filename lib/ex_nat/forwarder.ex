defmodule ExNat.Forwarder do
  use GenServer

  def child_spec(opts) do
    interface = Keyword.fetch!(opts, :interface)
    to_ip = Keyword.fetch!(opts, :to_ip)
    to_port = Keyword.fetch!(opts, :to_port)

    %{
      id: module_name(interface, to_ip, to_port),
      start: {__MODULE__, :start_link, opts}
    }
  end

  def start_link(opts = [interface, to_ip, to_port]) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  defp module_name(interface, to_ip, to_port) do
    Module.concat([__MODULE__, interface, "#{inspect(to_ip)}", "#{inspect(to_port)}"])
  end
end
