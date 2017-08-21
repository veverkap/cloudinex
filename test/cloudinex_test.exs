defmodule CloudinexTest do
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

  describe "debug logger" do
    test "debug logger", %{bypass: bypass} do
      Application.put_env(
      :cloudinex,
      :debug, true)
      response = load_fixture("ping")
      Bypass.expect bypass, fn conn ->
        assert "/demo/ping" == conn.request_path
        assert "GET" == conn.method
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end

      Cloudinex.ping

      Application.put_env(
      :cloudinex,
      :debug, false)
    end
  end

  describe "ping/0" do
    test "ping/0 returns proper response", %{bypass: bypass} do
      response = load_fixture("ping")
      Bypass.expect bypass, fn conn ->
        assert "/demo/ping" == conn.request_path
        assert "GET" == conn.method
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.ping
      assert body == Poison.decode!(response)
    end

    test "ping/0 handles rate limit", %{bypass: bypass} do
      Bypass.expect bypass, fn conn ->
        assert "/demo/ping" == conn.request_path
        assert "GET" == conn.method
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.put_resp_header("X-FeatureRateLimit-Limit", "500")
        |> Plug.Conn.put_resp_header("X-FeatureRateLimit-Remaining", "0")
        |> Plug.Conn.put_resp_header("X-FeatureRateLimit-Reset", "Wed, 03 Oct 2012 08:00:00 GMT")
        |> Plug.Conn.resp(420, ~s<{ "error": { "message": "Rate limit reached" } }>)
      end
      {:error, body} = Cloudinex.ping
      assert "Your rate limit will be reset on Wed, 03 Oct 2012 08:00:00 GMT" == body
    end

    test "ping/0 invalid credentials", %{bypass: bypass} do
      Bypass.expect bypass, fn conn ->
        assert "/demo/ping" == conn.request_path
        assert "GET" == conn.method
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.put_resp_header("X-FeatureRateLimit-Limit", "500")
        |> Plug.Conn.put_resp_header("X-FeatureRateLimit-Remaining", "0")
        |> Plug.Conn.put_resp_header("X-FeatureRateLimit-Reset", "Wed, 03 Oct 2012 08:00:00 GMT")
        |> Plug.Conn.resp(401, ~s<{"error":{"message":"Invalid credentials"}}>)
      end
      {:error, body} = Cloudinex.ping
      assert "Invalid Credentials: Please check your api_key and secret" == body
    end
  end

  describe "usage/0" do
    test "usage/0 returns proper response", %{bypass: bypass} do
      response = load_fixture("usage")
      Bypass.expect bypass, fn conn ->
        assert "/demo/usage" == conn.request_path
        assert "GET" == conn.method
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.usage
      assert body == Poison.decode!(response)
    end
  end

  describe "tags/1" do
    test "tags/1 returns proper response", %{bypass: bypass} do
      response = load_fixture("tags/image")
      Bypass.expect bypass, fn conn ->
        assert "/demo/tags/image" == conn.request_path
        assert "GET" == conn.method
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.tags(resource_type: "image")
      assert body == Poison.decode!(response)
    end

    test "tags/1 with prefix returns proper response", %{bypass: bypass} do
      response = load_fixture("tags/image/prefix_ap")
      Bypass.expect bypass, fn conn ->
        assert "/demo/tags/image" == conn.request_path
        assert "prefix=ap" == conn.query_string
        assert "GET" == conn.method
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.tags(resource_type: "image", prefix: "ap")
      assert body == Poison.decode!(response)
    end
  end
end
