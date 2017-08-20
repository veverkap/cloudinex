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

  describe "resource_types/0" do
    test "resource_types/0 returns proper response", %{bypass: bypass} do
      response = load_fixture("resources/types")
      Bypass.expect bypass, fn conn ->
        assert "/demo/resources" == conn.request_path
        assert "GET" == conn.method
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
      response = load_fixture("resources/images")
      Bypass.expect bypass, fn conn ->
        assert "/demo/resources/images" == conn.request_path
        assert "GET" == conn.method
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(400, response)
      end
      {:error, error_msg} = Cloudinex.resources(resource_type: "images")
      assert "Bad Request: Invalid value images for parameter resource_type" == error_msg
    end

    test "resources/1 loads image", %{bypass: bypass} do
      response = load_fixture("resources/image")
      Bypass.expect bypass, fn conn ->
        assert "/demo/resources/image" == conn.request_path
        assert "GET" == conn.method
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.resources(resource_type: "image")
      assert body == Poison.decode!(response)
    end

    test "resources/1 loads images of upload type", %{bypass: bypass} do
      response = load_fixture("resources/image/upload")
      Bypass.expect bypass, fn conn ->
        assert "/demo/resources/image/upload" == conn.request_path
        assert "GET" == conn.method
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.resources(resource_type: "image", type: "upload")
      assert body == Poison.decode!(response)
      Enum.each(body["resources"], fn(resource) ->
        assert resource["type"] == "upload"
      end)
    end

    test "resources/1 loads images of upload type with tags", %{bypass: bypass} do
      response = load_fixture("resources/image/tags/apple/tags_true")
      Bypass.expect bypass, fn conn ->
        assert "/demo/resources/image/upload" == conn.request_path
        assert "tags=true" == conn.query_string
        assert "GET" == conn.method
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.resources(resource_type: "image", type: "upload", tags: true)
      assert body == Poison.decode!(response)
      Enum.each(body["resources"], fn(resource) ->
        assert resource["tags"] == ["apple"]
      end)
    end

    test "resources/1 loads image and ignore bad keyword", %{bypass: bypass} do
      response = load_fixture("resources/image")
      Bypass.expect bypass, fn conn ->
        assert "/demo/resources/image" == conn.request_path
        assert "GET" == conn.method
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.resources(resource_type: "image", apple: "jo")
      assert body == Poison.decode!(response)
    end
  end

  describe "resources_by_tag/2" do
    test "resources_by_tag/2 won't load bad resource name", %{bypass: bypass} do
      response = load_fixture("resources/images/tags/apple")
      Bypass.expect bypass, fn conn ->
        assert "/demo/resources/images/tags/apple" == conn.request_path
        assert "GET" == conn.method
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(400, response)
      end
      {:error, error_msg} = Cloudinex.resources_by_tag("apple", resource_type: "images")
      assert "Bad Request: Invalid value images for parameter resource_type" == error_msg
    end

    test "resources_by_tag/2 loads valid resource name", %{bypass: bypass} do
      response = load_fixture("resources/image/tags/apple")
      Bypass.expect bypass, fn conn ->
        assert "/demo/resources/image/tags/apple" == conn.request_path
        assert "GET" == conn.method
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.resources_by_tag("apple", resource_type: "image")
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

  describe "resource/2" do
    test "resource/2 returns proper response", %{bypass: bypass} do
      response = load_fixture("resources/image/upload/bfch0noutwapaasvenin")
      Bypass.expect bypass, fn conn ->
        assert "/demo/resources/image/upload/bfch0noutwapaasvenin" == conn.request_path
        assert "GET" == conn.method
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.resource("bfch0noutwapaasvenin", resource_type: "image")
      assert body == Poison.decode!(response)
    end
  end

  describe "update_resource/2" do
    test "update_resource/2 returns proper response", %{bypass: bypass} do
      response = load_fixture("resources/image/upload/bfch0noutwapaasvenin")
      Bypass.expect bypass, fn conn ->
        assert "/demo/resources/image/upload/bfch0noutwapaasvenin" == conn.request_path
        assert "POST" == conn.method
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.update_resource("bfch0noutwapaasvenin", tags: ["cinammon"])
      assert body == Poison.decode!(response)
    end
  end

  describe "delete_resource/2" do
    test "delete_resource/2 returns proper response", %{bypass: bypass} do
      response = load_fixture("resources/image/upload/bfch0noutwapaasvenin/delete")
      Bypass.expect bypass, fn conn ->
        assert "/demo/resources/image/upload" == conn.request_path
        assert "DELETE" == conn.method
        assert "public_ids=bfch0noutwapaasvenin" == conn.query_string
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.delete_resource("bfch0noutwapaasvenin")
      assert body == Poison.decode!(response)
    end
  end

  describe "delete_resources/2" do
    test "delete_resources/2 with public_ids", %{bypass: bypass} do
      response = load_fixture("resources/image/upload/bfch0noutwapaasvenin-dude/delete")
      Bypass.expect bypass, fn conn ->
        assert "/demo/resources/image/upload" == conn.request_path
        assert "DELETE" == conn.method
        assert "public_ids=bfch0noutwapaasvenin%2Cdude" == conn.query_string
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      ids = ["bfch0noutwapaasvenin", "dude"]
      {:ok, body} = Cloudinex.delete_resources(%{public_ids: ids})
      assert body == Poison.decode!(response)
    end

    test "delete_resources/2 with public_ids binary", %{bypass: bypass} do
      response = load_fixture("resources/image/upload/bfch0noutwapaasvenin-dude/delete")
      Bypass.expect bypass, fn conn ->
        assert "/demo/resources/image/upload" == conn.request_path
        assert "DELETE" == conn.method
        assert "public_ids=bfch0noutwapaasvenin%2Cdude" == conn.query_string
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      ids = "bfch0noutwapaasvenin,dude"
      {:ok, body} = Cloudinex.delete_resources(%{public_ids: ids})
      assert body == Poison.decode!(response)
    end

    test "delete_resources/2 with public_ids binary and keep_original", %{bypass: bypass} do
      response = load_fixture("resources/image/upload/bfch0noutwapaasvenin-dude/delete")
      Bypass.expect bypass, fn conn ->
        assert "/demo/resources/image/upload" == conn.request_path
        assert "DELETE" == conn.method
        assert "keep_original=true&public_ids=bfch0noutwapaasvenin%2Cdude" == conn.query_string
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      ids = "bfch0noutwapaasvenin,dude"
      {:ok, body} = Cloudinex.delete_resources(%{public_ids: ids}, [keep_original: true])
      assert body == Poison.decode!(response)
    end

    test "delete_resources/2 with prefix binary", %{bypass: bypass} do
      response = load_fixture("resources/image/upload/bfch0noutwapaasvenin-dude/delete")
      Bypass.expect bypass, fn conn ->
        assert "/demo/resources/image/upload" == conn.request_path
        assert "DELETE" == conn.method
        assert "prefix=ap" == conn.query_string
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.delete_resources(%{prefix: "ap"})
      assert body == Poison.decode!(response)
    end

    test "delete_resources/2 with all", %{bypass: bypass} do
      response = load_fixture("resources/image/upload/bfch0noutwapaasvenin-dude/delete")
      Bypass.expect bypass, fn conn ->
        assert "/demo/resources/image/upload" == conn.request_path
        assert "DELETE" == conn.method
        assert "all=true" == conn.query_string
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.delete_resources(%{all: true})
      assert body == Poison.decode!(response)
    end

    test "delete_resources/2 with tag", %{bypass: bypass} do
      response = load_fixture("resources/image/upload/bfch0noutwapaasvenin-dude/delete")
      Bypass.expect bypass, fn conn ->
        assert "/demo/resources/image/tags/apple" == conn.request_path
        assert "DELETE" == conn.method
        assert "" == conn.query_string
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.delete_resources(%{tag: "apple"})
      assert body == Poison.decode!(response)
    end

    test "delete_resources/2 with tag and keep_original", %{bypass: bypass} do
      response = load_fixture("resources/image/upload/bfch0noutwapaasvenin-dude/delete")
      Bypass.expect bypass, fn conn ->
        assert "/demo/resources/image/tags/apple" == conn.request_path
        assert "DELETE" == conn.method
        assert "keep_original=true" == conn.query_string
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.delete_resources(%{tag: "apple"}, [keep_original: true])
      assert body == Poison.decode!(response)
    end

    test "delete_resources/2 with all and invalidate", %{bypass: bypass} do
      response = load_fixture("resources/image/upload/bfch0noutwapaasvenin-dude/delete")
      Bypass.expect bypass, fn conn ->
        assert "/demo/resources/image/upload" == conn.request_path
        assert "DELETE" == conn.method
        assert "invalidate=true&all=true" == conn.query_string
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.delete_resources(%{all: true}, [invalidate: true])
      assert body == Poison.decode!(response)
    end
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

  describe "upload_mappings/1" do
    test "upload_mappings/1 returns proper response", %{bypass: bypass} do
      response = load_fixture("upload_mappings")
      Bypass.expect bypass, fn conn ->
        assert "/demo/upload_mappings" == conn.request_path
        assert "GET" == conn.method
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.upload_mappings()
      assert body == Poison.decode!(response)
    end

    test "upload_mappings/1 with max_result returns proper response", %{bypass: bypass} do
      response = load_fixture("upload_mappings")
      Bypass.expect bypass, fn conn ->
        assert "/demo/upload_mappings" == conn.request_path
        assert "max_results=20" == conn.query_string
        assert "GET" == conn.method
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.upload_mappings(max_results: 20)
      assert body == Poison.decode!(response)
    end
  end

  describe "upload_mapping/1" do
    test "upload_mapping/1 returns proper response", %{bypass: bypass} do
      response = load_fixture("upload_mappings/my_map")
      Bypass.expect bypass, fn conn ->
        assert "/demo/upload_mappings/my_map" == conn.request_path
        assert "GET" == conn.method
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.upload_mapping("my_map")
      assert body == Poison.decode!(response)
    end
  end

  describe "create_upload_mapping/2" do
    test "create_upload_mapping/2 returns proper response", %{bypass: bypass} do
      response = load_fixture("upload_mappings/post")
      Bypass.expect bypass, fn conn ->
        assert "/demo/upload_mappings" == conn.request_path
        assert "POST" == conn.method
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.create_upload_mapping("folder", "template")
      assert body == Poison.decode!(response)
    end
  end

  describe "delete_upload_mapping/1" do
    test "delete_upload_mapping/1 returns proper response", %{bypass: bypass} do
      response = load_fixture("upload_mappings/my_map_delete")
      Bypass.expect bypass, fn conn ->
        assert "/demo/upload_mappings/my_map" == conn.request_path
        assert "DELETE" == conn.method
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.delete_upload_mapping("my_map")
      assert body == Poison.decode!(response)
    end
  end

  describe "update_upload_mapping/2" do
    test "update_upload_mapping/2 returns proper response", %{bypass: bypass} do
      response = load_fixture("upload_mappings/put")
      Bypass.expect bypass, fn conn ->
        assert "/demo/upload_mappings" == conn.request_path
        assert "PUT" == conn.method
        assert conn.query_string == "folder=yep&template=sure"
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end
      {:ok, body} = Cloudinex.update_upload_mapping("yep", "sure")
      assert body == Poison.decode!(response)
    end
  end
end
