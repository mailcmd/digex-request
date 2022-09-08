defmodule DigexRequest.MixProject do
  use Mix.Project

  @version "0.1.0"
  @repo "https://github.com/gBillal/digex-request"

  def project do
    [
      app: :digex_request,
      version: @version,
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      name: "DigexRequest",
      source_url: @repo,
      description: "Digest authentication implementation for Elixir",
      docs: [
        main: "DigexRequest",
        source_ref: "v#{@version}",
        source_url: @repo,
        extras: ["README.md"]
      ],
      package: [
        licenses: ["MIT"],
        links: %{
          "Github" => "https://github.com/gBillal/digex-request"
        }
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
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:bypass, "~> 2.1", only: :test}
    ]
  end
end
