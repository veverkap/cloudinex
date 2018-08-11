defmodule Cloudinex.ResourceTest do
  @moduledoc false
  use ExUnit.Case, async: false
  import Cloudinex.TestHelper

  setup do
    bypass = Bypass.open()

    Application.put_env(:cloudinex, :base_url, "http://localhost:#{bypass.port}/")

    {:ok, %{bypass: bypass}}
  end

  describe "resource_types/0" do
    test "resource_types/0 returns proper response", %{bypass: bypass} do
      response = load_fixture("resources/types")

      expect_json(bypass, fn conn ->
        assert "/demo/resources" == conn.request_path
        assert "GET" == conn.method

        conn
        |> Plug.Conn.resp(200, response)
      end)

      {:ok, body} = Cloudinex.resource_types()
      assert body == Jason.decode!(response)
    end
  end

  describe "resources/1" do
    test "resources/1 won't load bad resource name", %{bypass: bypass} do
      response = load_fixture("resources/images")

      expect_json(bypass, fn conn ->
        assert "/demo/resources/images" == conn.request_path
        assert "GET" == conn.method

        conn
        |> Plug.Conn.resp(400, response)
      end)

      {:error, error_msg} = Cloudinex.resources(resource_type: "images")
      assert "Bad Request: Invalid value images for parameter resource_type" == error_msg
    end

    test "resources/1 loads image", %{bypass: bypass} do
      response = load_fixture("resources/image")

      expect_json(bypass, fn conn ->
        assert "/demo/resources/image" == conn.request_path
        assert "GET" == conn.method

        conn
        |> Plug.Conn.resp(200, response)
      end)

      {:ok, body} = Cloudinex.resources(resource_type: "image")
      assert body == Jason.decode!(response)
    end

    test "resources/1 loads images of upload type", %{bypass: bypass} do
      response = load_fixture("resources/image/upload")

      expect_json(bypass, fn conn ->
        assert "/demo/resources/image/upload" == conn.request_path
        assert "GET" == conn.method

        conn
        |> Plug.Conn.resp(200, response)
      end)

      {:ok, body} = Cloudinex.resources(resource_type: "image", type: "upload")
      assert body == Jason.decode!(response)

      Enum.each(body["resources"], fn resource ->
        assert resource["type"] == "upload"
      end)
    end

    test "resources/1 loads images of upload type with tags", %{bypass: bypass} do
      response = load_fixture("resources/image/tags/apple/tags_true")

      expect_json(bypass, fn conn ->
        assert "/demo/resources/image/upload" == conn.request_path
        assert "tags=true" == conn.query_string
        assert "GET" == conn.method

        conn
        |> Plug.Conn.resp(200, response)
      end)

      {:ok, body} = Cloudinex.resources(resource_type: "image", type: "upload", tags: true)
      assert body == Jason.decode!(response)

      Enum.each(body["resources"], fn resource ->
        assert resource["tags"] == ["apple"]
      end)
    end

    test "resources/1 loads images of upload type with context", %{bypass: bypass} do
      response = load_fixture("resources/image/upload/context_true")

      expect_json(bypass, fn conn ->
        assert "/demo/resources/image/upload" == conn.request_path
        assert "context=true" == conn.query_string
        assert "GET" == conn.method

        conn
        |> Plug.Conn.resp(200, response)
      end)

      {:ok, body} = Cloudinex.resources(resource_type: "image", type: "upload", context: true)
      assert body == Jason.decode!(response)
      resource = List.first(body["resources"])
      assert resource["context"] == %{"custom" => %{"apple" => "joe", "frank" => "blow"}}
    end

    test "resources/1 loads image and ignore bad keyword", %{bypass: bypass} do
      response = load_fixture("resources/image")

      expect_json(bypass, fn conn ->
        assert "/demo/resources/image" == conn.request_path
        assert "GET" == conn.method

        conn
        |> Plug.Conn.resp(200, response)
      end)

      {:ok, body} = Cloudinex.resources(resource_type: "image", apple: "jo")
      assert body == Jason.decode!(response)
    end
  end

  describe "resources_by_tag/2" do
    test "resources_by_tag/2 won't load bad resource name", %{bypass: bypass} do
      response = load_fixture("resources/images/tags/apple")

      expect_json(bypass, fn conn ->
        assert "/demo/resources/images/tags/apple" == conn.request_path
        assert "GET" == conn.method

        conn
        |> Plug.Conn.resp(400, response)
      end)

      {:error, error_msg} = Cloudinex.resources_by_tag("apple", resource_type: "images")
      assert "Bad Request: Invalid value images for parameter resource_type" == error_msg
    end

    test "resources_by_tag/2 loads valid resource name", %{bypass: bypass} do
      response = load_fixture("resources/image/tags/apple")

      expect_json(bypass, fn conn ->
        assert "/demo/resources/image/tags/apple" == conn.request_path
        assert "GET" == conn.method

        conn
        |> Plug.Conn.resp(200, response)
      end)

      {:ok, body} = Cloudinex.resources_by_tag("apple", resource_type: "image")
      assert body == Jason.decode!(response)
    end
  end

  describe "resources_by_context/3" do
    test "resources_by_context/3 loads valid key", %{bypass: bypass} do
      response = load_fixture("resources/image/context/key_apple")

      expect_json(bypass, fn conn ->
        assert "/demo/resources/image/context/" == conn.request_path
        assert "GET" == conn.method
        assert "key=apple" == conn.query_string

        conn
        |> Plug.Conn.resp(200, response)
      end)

      {:ok, body} = Cloudinex.resources_by_context("apple", nil, resource_type: "image")
      assert body == Jason.decode!(response)
    end

    test "resources_by_context/3 loads valid key and value", %{bypass: bypass} do
      response = load_fixture("resources/image/context/key_apple")

      expect_json(bypass, fn conn ->
        assert "/demo/resources/image/context/" == conn.request_path
        assert "GET" == conn.method
        assert "key=apple&value=joe" == conn.query_string

        conn
        |> Plug.Conn.resp(200, response)
      end)

      {:ok, body} = Cloudinex.resources_by_context("apple", "joe", resource_type: "image")
      assert body == Jason.decode!(response)
    end
  end

  describe "resources_by_moderation/3" do
    test "resources_by_moderation/3 loads valid type", %{bypass: bypass} do
      response = load_fixture("resources/image/context/key_apple")

      expect_json(bypass, fn conn ->
        assert "/demo/resources/image/moderations/manual/pending" == conn.request_path
        assert "GET" == conn.method

        conn
        |> Plug.Conn.resp(200, response)
      end)

      {:ok, _body} = Cloudinex.resources_by_moderation("manual", "pending")
    end

    test "resources_by_moderation/3 raises on invalid type" do
      assert_raise FunctionClauseError, fn ->
        Cloudinex.resources_by_moderation("apple", "pending")
      end
    end

    test "resources_by_moderation/3 raises on invalid status" do
      assert_raise FunctionClauseError, fn ->
        Cloudinex.resources_by_moderation("manual", "apple")
      end
    end
  end

  describe "resource/2" do
    test "resource/2 returns proper response", %{bypass: bypass} do
      response = load_fixture("resources/image/upload/bfch0noutwapaasvenin")

      expect_json(bypass, fn conn ->
        assert "/demo/resources/image/upload/bfch0noutwapaasvenin" == conn.request_path
        assert "GET" == conn.method

        conn
        |> Plug.Conn.resp(200, response)
      end)

      {:ok, body} = Cloudinex.resource("bfch0noutwapaasvenin", resource_type: "image")
      assert body == Jason.decode!(response)
    end
  end

  describe "update_resource/2" do
    test "update_resource/2 returns proper response", %{bypass: bypass} do
      response = load_fixture("resources/image/upload/bfch0noutwapaasvenin")

      expect_json(bypass, fn conn ->
        assert "/demo/resources/image/upload/bfch0noutwapaasvenin" == conn.request_path
        assert "POST" == conn.method

        conn
        |> Plug.Conn.resp(200, response)
      end)

      {:ok, body} = Cloudinex.update_resource("bfch0noutwapaasvenin", tags: ["cinammon"])
      assert body == Jason.decode!(response)
    end
  end

  describe "update_access_mode/3" do
    test "update_access_mode/3 returns proper response w public_ids", %{bypass: bypass} do
      response = load_fixture("resources/image/upload/update_access_mode")

      expect_json(bypass, fn conn ->
        assert "/demo/resources/image/upload/update_access_mode" == conn.request_path
        assert "PUT" == conn.method
        assert "public_ids%5B%5D=bfch0noutwapaasvenin&access_mode=public" == conn.query_string

        conn
        |> Plug.Conn.resp(200, response)
      end)

      {:ok, _} = Cloudinex.update_access_mode(%{public_ids: ["bfch0noutwapaasvenin"]}, "public")
    end

    test "update_access_mode/3 returns proper response w tags", %{bypass: bypass} do
      response = load_fixture("resources/image/upload/update_access_mode")

      expect_json(bypass, fn conn ->
        assert "/demo/resources/image/upload/update_access_mode" == conn.request_path
        assert "PUT" == conn.method
        assert "tag=tag&access_mode=public" == conn.query_string

        conn
        |> Plug.Conn.resp(200, response)
      end)

      {:ok, _} = Cloudinex.update_access_mode(%{tag: "tag"}, "public")
    end

    test "update_access_mode/3 returns proper response w prefix", %{bypass: bypass} do
      response = load_fixture("resources/image/upload/update_access_mode")

      expect_json(bypass, fn conn ->
        assert "/demo/resources/image/upload/update_access_mode" == conn.request_path
        assert "PUT" == conn.method
        assert "prefix=tag&access_mode=public" == conn.query_string

        conn
        |> Plug.Conn.resp(200, response)
      end)

      {:ok, _} = Cloudinex.update_access_mode(%{prefix: "tag"}, "public")
    end
  end

  describe "restore" do
    test "restore loads correct url", %{bypass: bypass} do
      response = load_fixture("resources/image/upload/bfch0noutwapaasvenin/restore")

      expect_json(bypass, fn conn ->
        assert "/demo/resources/image/upload/restore" == conn.request_path
        assert "POST" == conn.method

        conn
        |> Plug.Conn.resp(200, response)
      end)

      {:ok, _body} = Cloudinex.restore_resource(["one", "two"])
    end
  end

  describe "delete_resource/2" do
    test "delete_resource/2 returns proper response", %{bypass: bypass} do
      response = load_fixture("resources/image/upload/bfch0noutwapaasvenin/delete")

      expect_json(bypass, fn conn ->
        assert "/demo/resources/image/upload" == conn.request_path
        assert "DELETE" == conn.method
        assert "public_ids=bfch0noutwapaasvenin" == conn.query_string

        conn
        |> Plug.Conn.resp(200, response)
      end)

      {:ok, body} = Cloudinex.delete_resource("bfch0noutwapaasvenin")
      assert body == Jason.decode!(response)
    end
  end

  describe "delete_resources/2" do
    test "delete_resources/2 with public_ids", %{bypass: bypass} do
      response = load_fixture("resources/image/upload/bfch0noutwapaasvenin-dude/delete")

      expect_json(bypass, fn conn ->
        assert "/demo/resources/image/upload" == conn.request_path
        assert "DELETE" == conn.method
        assert "public_ids=bfch0noutwapaasvenin%2Cdude" == conn.query_string

        conn
        |> Plug.Conn.resp(200, response)
      end)

      ids = ["bfch0noutwapaasvenin", "dude"]
      {:ok, body} = Cloudinex.delete_resources(%{public_ids: ids})
      assert body == Jason.decode!(response)
    end

    test "delete_resources/2 with public_ids binary", %{bypass: bypass} do
      response = load_fixture("resources/image/upload/bfch0noutwapaasvenin-dude/delete")

      expect_json(bypass, fn conn ->
        assert "/demo/resources/image/upload" == conn.request_path
        assert "DELETE" == conn.method
        assert "public_ids=bfch0noutwapaasvenin%2Cdude" == conn.query_string

        conn
        |> Plug.Conn.resp(200, response)
      end)

      ids = "bfch0noutwapaasvenin,dude"
      {:ok, body} = Cloudinex.delete_resources(%{public_ids: ids})
      assert body == Jason.decode!(response)
    end

    test "delete_resources/2 with public_ids binary and keep_original", %{bypass: bypass} do
      response = load_fixture("resources/image/upload/bfch0noutwapaasvenin-dude/delete")

      expect_json(bypass, fn conn ->
        assert "/demo/resources/image/upload" == conn.request_path
        assert "DELETE" == conn.method
        assert "keep_original=true&public_ids=bfch0noutwapaasvenin%2Cdude" == conn.query_string

        conn
        |> Plug.Conn.resp(200, response)
      end)

      ids = "bfch0noutwapaasvenin,dude"
      {:ok, body} = Cloudinex.delete_resources(%{public_ids: ids}, keep_original: true)
      assert body == Jason.decode!(response)
    end

    test "delete_resources/2 with prefix binary", %{bypass: bypass} do
      response = load_fixture("resources/image/upload/bfch0noutwapaasvenin-dude/delete")

      expect_json(bypass, fn conn ->
        assert "/demo/resources/image/upload" == conn.request_path
        assert "DELETE" == conn.method
        assert "prefix=ap" == conn.query_string

        conn
        |> Plug.Conn.resp(200, response)
      end)

      {:ok, body} = Cloudinex.delete_resources(%{prefix: "ap"})
      assert body == Jason.decode!(response)
    end

    test "delete_resources/2 with all", %{bypass: bypass} do
      response = load_fixture("resources/image/upload/bfch0noutwapaasvenin-dude/delete")

      expect_json(bypass, fn conn ->
        assert "/demo/resources/image/upload" == conn.request_path
        assert "DELETE" == conn.method
        assert "all=true" == conn.query_string

        conn
        |> Plug.Conn.resp(200, response)
      end)

      {:ok, body} = Cloudinex.delete_resources(%{all: true})
      assert body == Jason.decode!(response)
    end

    test "delete_resources/2 with tag", %{bypass: bypass} do
      response = load_fixture("resources/image/upload/bfch0noutwapaasvenin-dude/delete")

      expect_json(bypass, fn conn ->
        assert "/demo/resources/image/tags/apple" == conn.request_path
        assert "DELETE" == conn.method
        assert "" == conn.query_string

        conn
        |> Plug.Conn.resp(200, response)
      end)

      {:ok, body} = Cloudinex.delete_resources(%{tag: "apple"})
      assert body == Jason.decode!(response)
    end

    test "delete_resources/2 with tag and keep_original", %{bypass: bypass} do
      response = load_fixture("resources/image/upload/bfch0noutwapaasvenin-dude/delete")

      expect_json(bypass, fn conn ->
        assert "/demo/resources/image/tags/apple" == conn.request_path
        assert "DELETE" == conn.method
        assert "keep_original=true" == conn.query_string

        conn
        |> Plug.Conn.resp(200, response)
      end)

      {:ok, body} = Cloudinex.delete_resources(%{tag: "apple"}, keep_original: true)
      assert body == Jason.decode!(response)
    end

    test "delete_resources/2 with all and invalidate", %{bypass: bypass} do
      response = load_fixture("resources/image/upload/bfch0noutwapaasvenin-dude/delete")

      expect_json(bypass, fn conn ->
        assert "/demo/resources/image/upload" == conn.request_path
        assert "DELETE" == conn.method
        assert "invalidate=true&all=true" == conn.query_string

        conn
        |> Plug.Conn.resp(200, response)
      end)

      {:ok, body} = Cloudinex.delete_resources(%{all: true}, invalidate: true)
      assert body == Jason.decode!(response)
    end
  end

  describe "delete_derived_resources/2" do
    test "delete_derived_resources/2", %{bypass: bypass} do
      response = load_fixture("derived_resources_delete")

      expect_json(bypass, fn conn ->
        assert "/demo/derived_resources" == conn.request_path
        assert "DELETE" == conn.method

        assert "derived_resource_ids%5B%5D=a7b2a2756a&derived_resource_ids%5B%5D=dude" ==
                 conn.query_string

        conn
        |> Plug.Conn.resp(200, response)
      end)

      ids = ["a7b2a2756a", "dude"]
      {:ok, body} = Cloudinex.delete_derived_resources(ids)
      assert body == Jason.decode!(response)
    end
  end

  describe "delete_resources_by_prefix/2" do
    test "delete_resources/2 with prefix binary", %{bypass: bypass} do
      response = load_fixture("resources/image/upload/bfch0noutwapaasvenin-dude/delete")

      expect_json(bypass, fn conn ->
        assert "/demo/resources/image/upload" == conn.request_path
        assert "DELETE" == conn.method
        assert "prefix=ap" == conn.query_string

        conn
        |> Plug.Conn.resp(200, response)
      end)

      {:ok, body} = Cloudinex.delete_resources_by_prefix("ap")
      assert body == Jason.decode!(response)
    end
  end

  describe "delete_all_resources" do
    test "delete_all_resources/1", %{bypass: bypass} do
      response = load_fixture("resources/image/upload/bfch0noutwapaasvenin-dude/delete")

      expect_json(bypass, fn conn ->
        assert "/demo/resources/image/upload" == conn.request_path
        assert "DELETE" == conn.method
        assert "all=true" == conn.query_string

        conn
        |> Plug.Conn.resp(200, response)
      end)

      {:ok, body} = Cloudinex.delete_all_resources()
      assert body == Jason.decode!(response)
    end
  end

  describe "delete_resources_by_tag/2" do
    test "delete_resources_by_tag/2", %{bypass: bypass} do
      response = load_fixture("resources/image/upload/bfch0noutwapaasvenin-dude/delete")

      expect_json(bypass, fn conn ->
        assert "/demo/resources/image/tags/apple" == conn.request_path
        assert "DELETE" == conn.method
        assert "" == conn.query_string

        conn
        |> Plug.Conn.resp(200, response)
      end)

      {:ok, body} = Cloudinex.delete_resources_by_tag("apple")
      assert body == Jason.decode!(response)
    end
  end
end
