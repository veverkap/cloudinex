defmodule Cloudinex.TransformationTest do
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

  describe "transformations/1" do
    test "transformations/1 returns proper response", %{bypass: bypass} do
      response = load_fixture("transformations")
      Bypass.expect bypass, fn conn ->
        assert "/demo/transformations" == conn.request_path
        assert "GET" == conn.method
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.transformations()
      assert body == Poison.decode!(response)
    end

    test "transformations/1 with max_result returns proper response", %{bypass: bypass} do
      response = load_fixture("transformations")
      Bypass.expect bypass, fn conn ->
        assert "/demo/transformations" == conn.request_path
        assert "max_results=20" == conn.query_string
        assert "GET" == conn.method
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.transformations(max_results: 20)
      assert body == Poison.decode!(response)
    end
  end

  describe "transformation/1" do
    test "transformation/1 returns proper response", %{bypass: bypass} do
      response = load_fixture("transformations/c_crop,h_404,w_582,x_0,y_546")
      Bypass.expect bypass, fn conn ->
        assert "/demo/transformations/c_crop,h_404,w_582,x_0,y_546" == conn.request_path
        assert "GET" == conn.method
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.transformation("c_crop,h_404,w_582,x_0,y_546")
      assert body == Poison.decode!(response)
    end

    test "transformations/1 with max_result returns proper response", %{bypass: bypass} do
      response = load_fixture("transformations/c_crop,h_404,w_582,x_0,y_546")
      Bypass.expect bypass, fn conn ->
        assert "/demo/transformations/c_crop,h_404,w_582,x_0,y_546" == conn.request_path
        assert "max_results=20" == conn.query_string
        assert "GET" == conn.method
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.transformation("c_crop,h_404,w_582,x_0,y_546", max_results: 20)
      assert body == Poison.decode!(response)
    end
  end

  describe "delete_transformation/1" do
    test "delete_transformation/1 returns proper response", %{bypass: bypass} do
      response = load_fixture("transformations/delete")
      Bypass.expect bypass, fn conn ->
        assert "/demo/transformations/c_crop,h_404,w_582,x_0,y_546" == conn.request_path
        assert "DELETE" == conn.method
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.delete_transformation("c_crop,h_404,w_582,x_0,y_546")
      assert body == Poison.decode!(response)
    end
  end

  describe "update_transformation/2" do
    test "update_transformation/2 returns proper response", %{bypass: bypass} do
      response = load_fixture("transformations/put")
      Bypass.expect bypass, fn conn ->
        assert "/demo/transformations/c_crop,h_404,w_582,x_0,y_476" == conn.request_path
        assert "PUT" == conn.method
        assert conn.query_string == "allowed_for_strict=true"
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.update_transformation("c_crop,h_404,w_582,x_0,y_476", allowed_for_strict: true)
      assert body == Poison.decode!(response)
    end
  end

  describe "create_transformation/2" do
    test "create_transformation/2 returns proper response", %{bypass: bypass} do
      response = load_fixture("transformations/post")
      Bypass.expect bypass, fn conn ->
        assert "/demo/transformations/patrick" == conn.request_path
        assert "POST" == conn.method
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.create_transformation("patrick", "w_150,h_100,c_fill")
      assert body == Poison.decode!(response)
    end
  end
end
