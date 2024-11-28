defmodule DigexRequest.WWWAuthenticate do
  @moduledoc """
  The representation of a digest www-authenticate header
  """

  @quoted_regex ~r/(\w+)="(.*?)"/i
  @unquoted_regex ~r/(\w+)=([^" ,]*)/i

  @valid_algorithms ["MD5", "MD5-sess", "SHA-256", "SHA-256-sess"]

  @type t :: %__MODULE__{
          realm: String.t(),
          domain: list(String.t()),
          nonce: String.t(),
          opaque: String.t(),
          stale: boolean(),
          algorithm: atom(),
          qop: String.t(),
          charset: String.t(),
          userhash: boolean()
        }

  defstruct realm: nil,
            domain: nil,
            nonce: nil,
            opaque: nil,
            stale: false,
            algorithm: :md5,
            qop: nil,
            charset: "UTF-8",
            userhash: false

  @spec parse(String.t()) :: t()
  def parse(header) do
    header
    |> String.slice(7..-1//1)
    |> parse_header(@unquoted_regex)
    |> Map.merge(parse_header(header, @quoted_regex))
    |> map_to_struct()
  end

  defp parse_header(header, regex) do
    regex
    |> Regex.scan(header)
    |> Enum.map(fn [_, key, value] -> {key, value} end)
    |> Enum.into(%{})
  end

  defp map_to_struct(map) do
    Enum.reduce(map, %__MODULE__{}, fn
      {key, value}, acc when key in ["realm", "nonce", "opaque", "qop"] ->
        Map.put(acc, String.to_atom(key), value)

      {key, value}, acc when key in ["stale", "userhash"] and value in ["true", "TRUE"] ->
        Map.put(acc, String.to_atom(key), true)

      {"algorithm", algo}, acc when algo in @valid_algorithms ->
        %__MODULE__{acc | algorithm: String.to_atom(algo)}

      {"domain", domain}, acc ->
        %__MODULE__{acc | domain: String.split(domain, " ")}

      _, acc ->
        acc
    end)
  end
end
