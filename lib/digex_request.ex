defmodule DigexRequest do
  @moduledoc "README.md" |> File.read!()

  @type method :: :get | :head | :post | :delete | :put | :patch | :options | :trace
  @type headers() :: [{header_name :: String.t(), header_value :: String.t()}]

  @type options :: Keyword.t()

  @type t :: %__MODULE__{
          method: method(),
          url: String.t(),
          body: iodata(),
          username: String.t(),
          password: String.t(),
          headers: headers(),
          authorization: DigexRequest.Authorization.t() | nil
        }

  defstruct method: :get,
            url: nil,
            body: nil,
            headers: [],
            username: nil,
            password: nil,
            authorization: nil

  @doc """
  Send the query using an http client and map the response to `DigexRequest.Reponse` struct.

  The default implementation use the `httpc` http client to send requests.
  """
  @callback handle_request(method(), String.t(), headers(), any(), options()) ::
              {:ok, DigexRequest.Response.t()} | {:error, any()}

  @optional_callbacks handle_request: 5

  defmacro __using__(_opts) do
    quote do
      alias DigexRequest.{Authorization, WWWAuthenticate}

      @behaviour DigexRequest

      @spec request(DigexRequest.t(), DigexRequest.options()) ::
              {:ok, DigexRequest.Response.t(), DigexRequest.t()} | {:error, term()}
      def request(%DigexRequest{} = req, opts \\ []) do
        with {:ok, %{status: 401} = resp, req} <- do_request(req, opts) do
          case www_digest_header(resp.headers) do
            [] ->
              {:ok, resp, req}

            [header | _tail] ->
              do_request(
                %DigexRequest{
                  req
                  | authorization: build_authorization_from_header(header)
                },
                opts
              )
          end
        end
      end

      def handle_request(method, url, headers, body, opts) do
        Application.ensure_started(:inets)

        headers = Enum.map(headers, fn {k, v} -> {to_charlist(k), to_charlist(v)} end)

        request =
          if method == :get, do: {url, headers}, else: {url, headers, '', to_charlist(body)}

        with {:ok, {status, headers, body}} <- :httpc.request(method, request, opts, []) do
          headers = Enum.map(headers, fn {k, v} -> {to_string(k), to_string(v)} end)

          {:ok,
           %DigexRequest.Response{
             status: elem(status, 1),
             headers: headers,
             body: to_string(body)
           }}
        end
      end

      defp do_request(%DigexRequest{} = req, opts) do
        req = build_headers(req)

        case handle_request(req.method, req.url, req.headers, req.body, opts) do
          {:ok, resp} -> {:ok, resp, req}
          error -> error
        end
      end

      defp build_headers(%DigexRequest{authorization: nil} = req), do: req

      defp build_headers(%DigexRequest{authorization: auth} = req) do
        auth = Authorization.refresh(auth, req)
        headers = delete_authorization_header(req.headers)

        %DigexRequest{
          req
          | authorization: auth,
            headers: [{"authorization", Authorization.build(auth)} | headers]
        }
      end

      defp www_digest_header(headers) do
        headers
        |> Enum.filter(fn {key, value} ->
          key == "www-authenticate" and String.starts_with?(value, "Digest")
        end)
        |> Enum.map(fn {_, value} -> value end)
      end

      defp build_authorization_from_header(header) do
        header
        |> WWWAuthenticate.parse()
        |> Authorization.new()
      end

      defp delete_authorization_header(headers) do
        Enum.filter(headers, fn
          {"authorization", _} -> false
          {_, _} -> true
        end)
      end

      defoverridable handle_request: 5
    end
  end

  @doc """
  Build a digest request to be sent
  """
  @spec new(method(), String.t(), String.t(), String.t(), headers(), iodata() | nil) ::
          DigexRequest.t()
  def new(method, url, username, password, headers \\ [], body \\ nil) do
    %__MODULE__{
      method: method,
      url: url,
      headers: headers,
      body: body,
      username: username,
      password: password
    }
  end
end
