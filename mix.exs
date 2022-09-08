defmodule DigexRequest.MixProject do
  use Mix.Project

  def project do
    [
      app: :digex_request,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      name: "DigexRequest",
      source_url: "https://github.com/gBillal/digex-request",
      docs: [
        main: "DigexRequest",
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:crypto, :inets],
      mod: []
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end
end
