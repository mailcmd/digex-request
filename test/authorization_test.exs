defmodule DigexRequest.AuthorizationTest do
  @moduledoc """
  Test the response calculation and Authorization header generation.

  The examples used in the tests are taken fro RFC7616 document.
  """
  use ExUnit.Case

  alias DigexRequest.{Authorization, WWWAuthenticate}

  describe "calculate authorization header" do
    setup do
      www_header_1 =
        "Digest realm=\"http-auth@example.org\", qop=\"auth\", algorithm=SHA-256, nonce=\"7ypf/xlj9XXwfDPEoM4URrv/xwf94BcCAzFZH4GiTo0v\",
        opaque=\"FQhe/qaU925kfnzjCev0ciny7QMkPqMAFRtzCUYo5tdS\""

      www_header_2 =
        "Digest realm=\"http-auth@example.org\", qop=\"auth\", algorithm=MD5, nonce=\"7ypf/xlj9XXwfDPEoM4URrv/xwf94BcCAzFZH4GiTo0v\",
        opaque=\"FQhe/qaU925kfnzjCev0ciny7QMkPqMAFRtzCUYo5tdS\""

      {:ok, www_athenticate_1} = WWWAuthenticate.parse(www_header_1)
      {:ok, www_athenticate_2} = WWWAuthenticate.parse(www_header_2)

      auth_1 =
        Authorization.new(www_athenticate_1)
        |> Map.put(:cnonce, "f2/wE4q74E6zIJEtWaHKaf5wv/H5QzzpXusqGemxURZJ")

      auth_2 =
        Authorization.new(www_athenticate_2)
        |> Map.put(:cnonce, "f2/wE4q74E6zIJEtWaHKaf5wv/H5QzzpXusqGemxURZJ")

      req = %DigexRequest{
        method: :get,
        url: "http://www.example.org/dir/index.html",
        username: "Mufasa",
        password: "Circle of Life"
      }

      %{
        auth1: auth_1,
        auth2: auth_2,
        req: req
      }
    end

    test "calculate response", %{auth1: auth_1, auth2: auth_2, req: req} do
      assert %Authorization{
               response: "753927fa0e85d155564e2e272a28d1802ca10daf4496794697cf8db5856cb6c1",
               nc: 1
             } = Authorization.refresh(auth_1, req)

      assert %Authorization{response: "8ca523f5e9506fed4657c9700eebdbec", nc: 1} =
               Authorization.refresh(auth_2, req)
    end

    test "build the authorization header", %{auth1: auth_1, auth2: auth_2, req: req} do
      auth_header = Authorization.refresh(auth_1, req) |> Authorization.build()

      assert String.starts_with?(auth_header, "Digest")
      assert {_idx, _} = :binary.match(auth_header, "username=\"Mufasa\"")
      assert {_idx, _} = :binary.match(auth_header, "realm=\"http-auth@example.org\"")
      assert {_idx, _} = :binary.match(auth_header, "uri=\"/dir/index.html\"")
      assert {_idx, _} = :binary.match(auth_header, "nc=00000001")

      assert {_idx, _} =
               :binary.match(
                 auth_header,
                 "response=\"753927fa0e85d155564e2e272a28d1802ca10daf4496794697cf8db5856cb6c1\""
               )

      assert {_idx, _} =
               :binary.match(
                 auth_header,
                 "opaque=\"FQhe/qaU925kfnzjCev0ciny7QMkPqMAFRtzCUYo5tdS\""
               )

      auth_header = Authorization.refresh(auth_2, req) |> Authorization.build()

      assert String.starts_with?(auth_header, "Digest")

      assert {_idx, _} =
               :binary.match(auth_header, "response=\"8ca523f5e9506fed4657c9700eebdbec\"")

      assert {_idx, _} =
               :binary.match(
                 auth_header,
                 "opaque=\"FQhe/qaU925kfnzjCev0ciny7QMkPqMAFRtzCUYo5tdS\""
               )
    end

    test "hash user when userhash is true", %{auth1: auth_1, req: req} do
      auth_1 = %Authorization{auth_1 | realm: "api@example.org", userhash: true}
      req = %DigexRequest{req | username: "Jäsøn Doe"}

      auth_header = Authorization.refresh(auth_1, req) |> Authorization.build()

      assert String.starts_with?(auth_header, "Digest")

      assert {_idx, _} =
               :binary.match(
                 auth_header,
                 "username=\"5a1a8a47df5c298551b9b42ba9b05835174a5bd7d511ff7fe9191d8e946fc4e7\""
               )
    end
  end
end
