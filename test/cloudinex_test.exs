defmodule CloudinexTest do
  @moduledoc false
  use ExUnit.Case
  import Cloudinex.TestHelper

  setup do
    bypass = Bypass.open

    Application.put_env(
      :cloudinex,
      :base_url, "http://localhost:#{bypass.port}/")

    {:ok, %{bypass: bypass}}
  end

  describe "ping/0" do
    test "ping/0 returns proper response", %{bypass: bypass} do
      response = load_fixture("ping")
      Bypass.expect bypass, fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.ping
      assert body == Poison.decode!(response)
    end

    test "ping/0 handles rate limit", %{bypass: bypass} do
      Bypass.expect bypass, fn conn ->
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
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.usage
      assert body == Poison.decode!(response)
    end
  end

  describe "resource_types/0" do
    test "resource_types/0 returns proper response", %{bypass: bypass} do
      response = load_fixture("resource_types")
      Bypass.expect bypass, fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.resource_types
      assert body == Poison.decode!(response)
    end
  end

  describe "resources/1" do
    test "resources/1 won't load bad resource name", %{bypass: bypass} do
      response = load_fixture("resources_images")
      Bypass.expect bypass, fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(400, response)
      end
      {:error, error_msg} = Cloudinex.resources(resource_type: "images")
      assert "Bad Request: Invalid value images for parameter resource_type" == error_msg
    end

    test "resources/1 loads image", %{bypass: bypass} do
      response = load_fixture("resources_image")
      Bypass.expect bypass, fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.resources(resource_type: "image")
      assert body == Poison.decode!(response)
    end

    test "resources/1 loads images of upload type", %{bypass: bypass} do
      response = load_fixture("resources_image_upload")
      Bypass.expect bypass, fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.resources(resource_type: "image", type: "upload")
      assert body == Poison.decode!(response)
    end
  end

  describe "resources_by_tag/2" do
    test "resources_by_tag/2 won't load bad resource name", %{bypass: bypass} do
      response = load_fixture("resources_images_tags_apple")
      Bypass.expect bypass, fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(400, response)
      end
      {:error, error_msg} = Cloudinex.resources_by_tag("apple", resource_type: "images")
      assert "Bad Request: Invalid value images for parameter resource_type" == error_msg
    end

    test "resources_by_tag/2 loads valid resource name", %{bypass: bypass} do
      response = load_fixture("resources_image_tags_apple")
      Bypass.expect bypass, fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.resources_by_tag("apple", resource_type: "image")
      assert body == Poison.decode!(response)
    end
  end
end
