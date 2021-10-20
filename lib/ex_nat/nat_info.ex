defmodule ExNat.NatInfo do
  defstruct [
    :from_ip,
    :from_port,
    :to_ip,
    :to_port,
    :transport,
    :packet
  ]
end
