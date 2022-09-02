defmodule DigexRequest.WwwAuthenticateTest do
  use ExUnit.Case

  alias DigexRequest.WWWAuthenticate

  test "parse www-authenticate header" do
    header_1 =
      "Digest qop=\"auth-int\", nonce=\"54545dfsdfsdf8778979fd\", realm=\"realm\", opaque=\"random string\""

    header_2 =
      "Basic realm=\"basic realm\", Digest realm=\"digest realm\", algorithm=\"SHA-256-sess\""

    expected_www_authenticate_1 = %WWWAuthenticate{
      qop: "auth-int",
      nonce: "54545dfsdfsdf8778979fd",
      realm: "realm",
      opaque: "random string"
    }

    expected_www_authenticate_2 = %WWWAuthenticate{
      algorithm: :"SHA-256-sess",
      realm: "digest realm"
    }

    assert {:ok, ^expected_www_authenticate_1} = WWWAuthenticate.parse(header_1)
    assert {:ok, ^expected_www_authenticate_2} = WWWAuthenticate.parse(header_2)
  end

  test "parse invalid www-authenticate header" do
    header = "Basic realm=\"Basic realm\""

    assert :error = WWWAuthenticate.parse(header)
  end
end
