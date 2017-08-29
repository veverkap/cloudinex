defmodule Cloudinex.UploadMappingTest do
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

  describe "upload_mappings/1" do
    test "upload_mappings/1 returns proper response", %{bypass: bypass} do
      response = load_fixture("upload_mappings")
      expect_json bypass, fn conn ->
        assert "/demo/upload_mappings" == conn.request_path
        assert "GET" == conn.method
        conn
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.upload_mappings()
      assert body == Poison.decode!(response)
    end

    test "upload_mappings/1 with max_result returns proper response", %{bypass: bypass} do
      response = load_fixture("upload_mappings")
      expect_json bypass, fn conn ->
        assert "/demo/upload_mappings" == conn.request_path
        assert "max_results=20" == conn.query_string
        assert "GET" == conn.method
        conn
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.upload_mappings(max_results: 20)
      assert body == Poison.decode!(response)
    end
  end

  describe "upload_mapping/1" do
    test "upload_mapping/1 returns proper response", %{bypass: bypass} do
      response = load_fixture("upload_mappings/my_map")
      expect_json bypass, fn conn ->
        assert "/demo/upload_mappings/my_map" == conn.request_path
        assert "GET" == conn.method
        conn
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.upload_mapping("my_map")
      assert body == Poison.decode!(response)
    end
  end

  describe "create_upload_mapping/2" do
    test "create_upload_mapping/2 returns proper response", %{bypass: bypass} do
      response = load_fixture("upload_mappings/post")
      expect_json bypass, fn conn ->
        assert "/demo/upload_mappings" == conn.request_path
        assert "POST" == conn.method
        conn
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.create_upload_mapping("folder", "template")
      assert body == Poison.decode!(response)
    end
  end

  describe "delete_upload_mapping/1" do
    test "delete_upload_mapping/1 returns proper response", %{bypass: bypass} do
      response = load_fixture("upload_mappings/my_map_delete")
      expect_json bypass, fn conn ->
        assert "/demo/upload_mappings/my_map" == conn.request_path
        assert "DELETE" == conn.method
        conn
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.delete_upload_mapping("my_map")
      assert body == Poison.decode!(response)
    end
  end

  describe "update_upload_mapping/2" do
    test "update_upload_mapping/2 returns proper response", %{bypass: bypass} do
      response = load_fixture("upload_mappings/put")
      expect_json bypass, fn conn ->
        assert "/demo/upload_mappings" == conn.request_path
        assert "PUT" == conn.method
        assert conn.query_string == "folder=yep&template=sure"
        conn
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.update_upload_mapping("yep", "sure")
      assert body == Poison.decode!(response)
    end
  end
end
