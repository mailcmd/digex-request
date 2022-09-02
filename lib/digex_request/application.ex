defmodule DigexRequest.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Finch, name: Finch}
    ]

    opts = [strategy: :one_for_one, name: DigexRequest.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
