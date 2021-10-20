defmodule ExNat.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_nat,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :pkt],
      mod: {ExNat.Application, []}
    ]
  end

  defp deps do
    [
      {:epcap, git: "https://github.com/msantos/epcap", tag: "1.1.0"}
    ]
  end
end
