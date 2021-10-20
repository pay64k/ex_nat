defmodule ExNat.Application do
  @moduledoc false

  use Application

  alias ExNat.Listener

  @impl true
  def start(_type, _args) do
    children = [
      Listener.child_spec(
        interface: "enp0s3",
        transport: :udp,
        from_ip: {172, 19, 0, 15},
        from_port: 45892
      ),
      Listener.child_spec(
        interface: "docker0",
        transport: :udp,
        from_ip: {172, 19, 0, 2},
        from_port: 5671
      )
    ]

    opts = [strategy: :one_for_one, name: ExNat.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
