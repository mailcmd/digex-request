# DigexRequest

A digest access authentication implementation for `Elixir`. It tries to follow `RFC 7616` as much as possible.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `digex_request` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:digex_request, "~> 0.1.0"}
  ]
end
```

## Usage

To use the digest request, you need to create a module and use the `DigexRequest` behaviour

```elixir
def DigexClient do
  use DigexRequest
end
```

after that, build a request and send it:

```elixir
DigexRequest.new(:get, "http://www.example.com", "username", "password") |> DigexClient.request()
```

By default the http client used is `:httpc`, you can override this behaviour by implementing the 
`handle_request/4` function.

For example if we want to use Finch to send the request

```elixir
def DigexClient do
  use DigexRequest

  @impl DigexRequest
  def handle_request(method, url, headers, body) do
    case Finch.build(method, url, headers, body) |> Finch.request(MyFinch) do
      {:ok, response} ->
        {:ok, 
          %DigexRequest.Response{
            status: response.status, 
            headers: response.headers, 
            body: response.body}}

      {:error, error} ->
        {:error, error}
    end
  end
end
```

## Authorization header refresh

Each call made by the client will update the `DigexRequest` struct, so you need to keep this request 
in order to reuse the authorization header.

```elixir
req = DigexRequest.new(:get, "http://www.example.com", "username", "password")
{:ok, resp, req} = DigexClient.request(req)

# re-use the authorization header for another path
req = %DigexRequest{req | url: "http://www.example.com/another/path"}
{:ok, resp, req} = DigexClient.request(req)
```

