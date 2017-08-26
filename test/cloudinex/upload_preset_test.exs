defmodule Cloudinex.UploadPresetTest do
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

  describe "upload_presets/1" do
    test "upload_presets/1 returns proper response", %{bypass: bypass} do
      response = load_fixture("upload_presets")
      Bypass.expect bypass, fn conn ->
        assert "/demo/upload_presets" == conn.request_path
        assert "GET" == conn.method
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.upload_presets()
      assert body == Poison.decode!(response)
    end

    test "upload_presets/1 with max_result returns proper response", %{bypass: bypass} do
      response = load_fixture("upload_presets")
      Bypass.expect bypass, fn conn ->
        assert "/demo/upload_presets" == conn.request_path
        assert "max_results=20" == conn.query_string
        assert "GET" == conn.method
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.upload_presets(max_results: 20)
      assert body == Poison.decode!(response)
    end
  end

  describe "upload_preset/1" do
    test "upload_preset/1 returns proper response", %{bypass: bypass} do
      response = load_fixture("upload_presets/xyemrxup")
      Bypass.expect bypass, fn conn ->
        assert "/demo/upload_presets/xyemrxup" == conn.request_path
        assert "GET" == conn.method
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.upload_preset("xyemrxup")
      assert body == Poison.decode!(response)
    end
  end

  describe "create_upload_preset/2" do
    test "create_upload_preset/2 returns proper response", %{bypass: bypass} do
      response = load_fixture("upload_presets/post")
      Bypass.expect bypass, fn conn ->
        assert "/demo/upload_presets" == conn.request_path
        assert "POST" == conn.method
        assert "" == conn.query_string
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, _} = Cloudinex.create_upload_preset("aflaksdfsdf", true, true, tags: "remote", allowed_formats: "jpg,png")
    end
  end

  describe "delete_upload_preset/2" do
    test "delete_upload_preset/2 returns proper response", %{bypass: bypass} do
      response = load_fixture("upload_presets/delete")
      Bypass.expect bypass, fn conn ->
        assert "/demo/upload_presets/testsfasfdff" == conn.request_path
        assert "DELETE" == conn.method
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, _} = Cloudinex.delete_upload_preset("testsfasfdff")
    end
  end

  describe "update_upload_preset/2" do
    test "update_upload_preset/2 returns proper response", %{bypass: bypass} do
      response = load_fixture("upload_presets/put")
      Bypass.expect bypass, fn conn ->
        assert "/demo/upload_presets/applebottom2" == conn.request_path
        assert "PUT" == conn.method
        assert conn.query_string == "tags=yolo"
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, _} = Cloudinex.update_upload_preset("applebottom2", tags: "yolo")
    end
  end
end
