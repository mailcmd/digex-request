defmodule DigexRequest do
  @moduledoc false

  @type method :: :get | :head | :post | :delete | :put | :patch | :options | :trace

  @type t :: %__MODULE__{
          method: method(),
          url: String.t(),
          body: any(),
          username: String.t(),
          password: String.t(),
          authorization: DigexRequest.Authorization.t()
        }

  defstruct method: :get,
            url: nil,
            body: nil,
            username: nil,
            password: nil,
            authorization: nil
end
