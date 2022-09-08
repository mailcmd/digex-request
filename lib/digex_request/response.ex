defmodule DigexRequest.Response do
  @moduledoc """
  A response to a request
  """

  @type t :: %__MODULE__{
          status: non_neg_integer(),
          headers: DigexRequest.headers(),
          body: iodata() | nil
        }

  defstruct [:status, :body, :headers]
end
