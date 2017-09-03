defmodule Cloudinex.FoldersTest do
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

  describe "list_root_folders/0" do
    test "folders/0 returns proper response", %{bypass: bypass} do
      response = load_fixture("folders")
      expect_json bypass, fn conn ->
        assert "/demo/folders" == conn.request_path
        assert "GET" == conn.method
        conn
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.folders()
      assert body == Poison.decode!(response)
    end
  end

  describe "folders/1" do
    test "folders/1 returns proper response", %{bypass: bypass} do
      response = load_fixture("folders/slippy")
      expect_json bypass, fn conn ->
        assert "/demo/folders/slippy" == conn.request_path
        assert "GET" == conn.method
        conn
        |> Plug.Conn.resp(200, response)
      end
      {:ok, _} = Cloudinex.folders("slippy")
    end

    test "folders/1 with_subfolder returns proper response", %{bypass: bypass} do
      response = load_fixture("folders/slippy/subfolder")
      expect_json bypass, fn conn ->
        assert "/demo/folders/slippy/subfolder" == conn.request_path
        assert "GET" == conn.method
        conn
        |> Plug.Conn.resp(200, response)
      end
      {:ok, _} = Cloudinex.folders("slippy/subfolder")
    end
  end
end
