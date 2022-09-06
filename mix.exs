defmodule DigexRequest.MixProject do
  use Mix.Project

  def project do
    [
      app: :digex_request,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:crypto, :inets],
      mod: []
    ]
  end

  defp deps do
    []
  end
end
