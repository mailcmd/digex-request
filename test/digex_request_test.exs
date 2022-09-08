defmodule DigexRequestTest do
  use ExUnit.Case

  alias Plug.Conn

  setup_all do
    Application.ensure_started(:inets)

    defmodule DigexClient do
      use DigexRequest
    end

    {:ok, client: DigexClient}
  end

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  test "client handle digest authentication", %{bypass: bypass, client: client} do
    Bypass.expect(bypass, "GET", "/resource", fn conn ->
      case Conn.get_req_header(conn, "authorization") do
        [] ->
          conn
          |> Conn.put_resp_header("www-authenticate", "Digest realm=\"realm\", nonce=\"1fd54f4d5f5d4sfdsf\", qop=\"auth\"")
          |> Conn.resp(401, "")

        [authorization] ->
          assert authorization =~ "1fd54f4d5f5d4sfdsf"

          conn
          |> Conn.put_resp_content_type("application/json")
          |> Conn.resp(200, ~s({"status": "ok"}))
      end
    end)

    req = DigexRequest.new(:get, "#{url(bypass.port)}/resource", "admin", "username")
    assert {:ok, %{status: 200, body: ~s<{"status": "ok"}>}, _} = client.request(req)
  end

  test "returns other responses without retrying", %{bypass: bypass, client: client} do
    Bypass.expect_once(bypass, "GET", "/resource", fn conn ->
      conn
      |> Conn.put_resp_header("www-authenticate", ~s<Basic realm="basic">)
      |> Conn.resp(401, "")
    end)

    req = DigexRequest.new(:get, "#{url(bypass.port)}/resource", "admin", "username")
    assert {:ok, %{status: 401}, %DigexRequest{authorization: nil}} = client.request(req)
  end

  defp url(port) do
    "http://localhost:#{port}"
  end
end
