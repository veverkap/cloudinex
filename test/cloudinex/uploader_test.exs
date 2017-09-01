defmodule Cloudinex.UploaderTest do
  @moduledoc false
  use ExUnit.Case, async: false
  import Cloudinex.TestHelper

  setup do
    bypass = Bypass.open

    Application.put_env(
      :cloudinex,
      :base_url, "http://localhost:#{bypass.port}/")

    {:ok, %{bypass: bypass}}
  end

  test "uploads url", %{bypass: bypass} do
    response = load_fixture("folders")
    Bypass.expect bypass, fn conn ->
      assert "/demo/image/upload" == conn.request_path
      assert "POST" == conn.method
      {:ok, body, conn} = Plug.Conn.read_body(conn, length: 1_000_000)
      assert body =~ "example.jpg"
      conn
      |> Plug.Conn.resp(200, response)
    end
    Cloudinex.Uploader.upload("http://example.com/example.jpg")
  end

  test "uploads secure url", %{bypass: bypass} do
    response = load_fixture("folders")
    Bypass.expect bypass, fn conn ->
      assert "/demo/image/upload" == conn.request_path
      assert "POST" == conn.method
      {:ok, body, conn} = Plug.Conn.read_body(conn, length: 1_000_000)
      assert body =~ "example.jpg"
      conn
      |> Plug.Conn.resp(200, response)
    end
    Cloudinex.Uploader.upload("https://example.com/example.jpg")
  end

  test "uploads image", %{bypass: bypass} do
    response = load_fixture("folders")
    Bypass.expect bypass, fn conn ->
      assert "/demo/image/upload" == conn.request_path
      assert "POST" == conn.method
      {:ok, _, conn} = Plug.Conn.read_body(conn, length: 1_000_000)
      assert Enum.any?(conn.req_headers, fn({a,b}) ->
        a == "content-length" && b == "8381"
      end)

      conn
      |> Plug.Conn.resp(200, response)
    end
    Cloudinex.Uploader.upload("./test/fixtures/logo.png")
  end
end
