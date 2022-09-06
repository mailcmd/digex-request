defmodule DigexRequest.Response do
  @moduledoc false

  @type t :: %__MODULE__{
          status: non_neg_integer(),
          headers: DigexRequest.headers(),
          body: iodata() | nil
        }

  defstruct [:status, :body, :headers]
end
