defmodule Cloudinex.UploaderTest do
  @moduledoc false
  use ExUnit.Case, async: false
  import Cloudinex.TestHelper

  setup do
    bypass = Bypass.open

    Application.put_env(
      :cloudinex,
      :base_url, "http://localhost:#{bypass.port}/")

    Application.put_env(
      :cloudinex,
      :api_key, "fakeapikey")

    Application.put_env(
      :cloudinex,
      :secret, "somefakestring")

    {:ok, %{bypass: bypass}}
  end

  test "uploads text", %{bypass: bypass} do
    response = load_fixture("folders")
    Bypass.expect bypass, fn conn ->
      assert "/demo/image/text" == conn.request_path
      assert "POST" == conn.method
      {:ok, body, conn} = Plug.Conn.read_body(conn, length: 1_000_000)
      assert body =~ "text=apple"
      conn
      |> Plug.Conn.resp(200, response)
    end
    Cloudinex.Uploader.upload_text("apple")
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
    Cloudinex.Uploader.upload_url("http://example.com/example.jpg")
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
    Cloudinex.Uploader.upload_url("https://example.com/example.jpg")
  end

  test "uploads data:uri", %{bypass: bypass} do
    value = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg=="
    response = load_fixture("folders")
    Bypass.expect bypass, fn conn ->
      assert "/demo/image/upload" == conn.request_path
      assert "POST" == conn.method
      {:ok, body, conn} = Plug.Conn.read_body(conn, length: 1_000_000)
      assert body =~ "iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4"
      conn
      |> Plug.Conn.resp(200, response)
    end
    Cloudinex.Uploader.upload_url(value)
  end

  test "uploads image", %{bypass: bypass} do
    response = load_fixture("folders")
    Bypass.expect bypass, fn conn ->
      assert "/demo/image/upload" == conn.request_path
      assert "POST" == conn.method
      {:ok, _, conn} = Plug.Conn.read_body(conn, length: 1_000_000)

      conn
      |> Plug.Conn.resp(200, response)
    end
    Cloudinex.Uploader.upload_file("./test/fixtures/logo.png")
  end
end
