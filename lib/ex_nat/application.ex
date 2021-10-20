defmodule ExNat.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {ExNat.Worker, [interface: "enp0s3", transport: :tcp]}
    ]

    opts = [strategy: :one_for_one, name: ExNat.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
