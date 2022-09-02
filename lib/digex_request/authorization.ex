defmodule DigexRequest.Authorization do
  @moduledoc """
  Build the authorization header for the digest request
  """

  alias __MODULE__

  @type t :: %__MODULE__{
          response: String.t(),
          username: String.t(),
          realm: String.t(),
          uri: String.t(),
          qop: String.t(),
          opaque: String.t(),
          nonce: String.t(),
          cnonce: String.t(),
          nc: non_neg_integer(),
          userhash: boolean(),
          algorithm: atom()
        }

  defstruct response: nil,
            username: nil,
            realm: nil,
            uri: nil,
            qop: nil,
            nonce: nil,
            opaque: nil,
            cnonce: nil,
            nc: 0,
            userhash: false,
            algorithm: :MD5

  @spec new(DigexRequest.WWWAuthenticate.t()) :: t()
  def new(%DigexRequest.WWWAuthenticate{} = wwwAuthenticate) do
    %Authorization{
      realm: wwwAuthenticate.realm,
      qop: wwwAuthenticate.qop,
      userhash: wwwAuthenticate.userhash,
      nonce: wwwAuthenticate.nonce,
      opaque: wwwAuthenticate.opaque,
      algorithm: wwwAuthenticate.algorithm,
      cnonce: generate_cnonce()
    }
  end

  @spec refresh(t(), DigexRequest.t()) :: t()
  def refresh(%Authorization{} = authorization, %DigexRequest{} = dr) do
    authorization = %Authorization{
      authorization
      | username: dr.username,
        uri: path(dr.url),
        nc: authorization.nc + 1
    }

    computeResponse(authorization, dr)
  end

  def build(%__MODULE__{} = auth) do
    auth
    |> Map.from_struct()
    |> Map.put(:username, maybe_hash_username(auth))
    |> Map.put(:nc, formatNc(auth.nc))
    |> Enum.filter(&(!is_nil(elem(&1, 1))))
    |> Enum.map(fn
      {key, value} when key in [:algorithm, :qop, :nc] -> "#{key}=#{value}"
      {key, value} -> "#{key}=\"#{value}\""
    end)
    |> Enum.join(", ")
    |> then(&"Digest #{&1}")
  end

  @spec path(String.t()) :: String.t()
  defp path(url) do
    URI.parse(url).path
  end

  defp generate_cnonce() do
    :crypto.strong_rand_bytes(10)
    |> Base.encode16(case: :lower)
  end

  defp computeResponse(%__MODULE__{} = auth, %DigexRequest{} = dr) do
    a1_hash = compute(:a1, auth, dr) |> hash(auth)
    a2_hash = compute(:a2, auth, dr) |> hash(auth)

    response =
      [a1_hash, auth.nonce, formatNc(auth.nc), auth.cnonce, auth.qop, a2_hash]
      |> Enum.join(":")
      |> hash(auth)

    %__MODULE__{auth | response: response}
  end

  defp compute(:a1, %__MODULE__{} = auth, dr) do
    base = auth.username <> ":" <> auth.realm <> ":" <> dr.password

    if sess?(auth.algorithm),
      do: hash(base, auth) <> ":" <> auth.nonce <> ":" <> auth.cnonce,
      else: base
  end

  defp compute(:a2, %__MODULE__{qop: "auth-int"} = auth, dr) do
    String.upcase("#{dr.method}") <> ":" <> auth.uri <> ":" <> hash(dr.body || "", auth)
  end

  defp compute(:a2, auth, dr) do
    String.upcase("#{dr.method}") <> ":" <> auth.uri
  end

  defp hash(data, %__MODULE__{algorithm: algo}) do
    hash_function(algo)
    |> :crypto.hash(data)
    |> Base.encode16(case: :lower)
  end

  defp hash_function(algorithm) when algorithm in [:"SHA-256", :"SHA-256-sess"], do: :sha256
  defp hash_function(_), do: :md5

  defp sess?(algorithm), do: to_string(algorithm) |> String.ends_with?("sess")

  defp formatNc(value) do
    value
    |> Integer.to_string(16)
    |> String.downcase()
    |> String.pad_leading(8, "0")
  end

  defp maybe_hash_username(%__MODULE__{username: username, userhash: true} = auth) do
    hash(username <> ":" <> auth.realm, auth)
  end

  defp maybe_hash_username(auth), do: auth.username
end
