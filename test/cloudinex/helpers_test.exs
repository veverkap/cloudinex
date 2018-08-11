defmodule Cloudinex.HelpersTest do
  @moduledoc false
  alias Cloudinex.Helpers
  use ExUnit.Case

  describe "unify/1" do
    test "unify/1 handles nil" do
      assert nil == Helpers.unify(nil)
    end

    test "unify/1 handles enumerable" do
      assert %{"a" => 1} == Helpers.unify(%{a: 1})
    end
  end

  describe "join_list/1" do
    test "join_list/1 handles nil" do
      assert "" == Helpers.join_list(nil)
    end

    test "join_list/1 joins strings" do
      assert "a,b" == Helpers.join_list(["a", "b"])
    end

    test "join_list/1 joins numbers" do
      assert "1,2" == Helpers.join_list([1, 2])
    end
  end

  describe "map_context/1" do
    test "map_context/1 handles nil" do
      assert nil == Helpers.map_context(nil)
    end

    test "map_context/1 joins" do
      assert "a=b" == Helpers.map_context(%{a: "b"})
    end
  end

  describe "map_coordinates/1" do
    test "map_coordinates/1 handles nil" do
      assert nil == Helpers.map_coordinates(nil)
    end

    test "map_coordinates/1 maps list" do
      assert "a,b,c,d" == Helpers.map_coordinates([{"a", "b", "c", "d"}])
    end
  end

  describe "prepare_opts/1" do
    test "prepare_opts/1 echos when not map" do
      assert nil == Helpers.prepare_opts(nil)
      assert "" == Helpers.prepare_opts("")
    end

    test "prepare_opts/1 joins nested things" do
      under_test = %{tags: ["apple", "chicken"], pizza: "green"}
      assert %{pizza: "green", tags: "apple,chicken"} == Helpers.prepare_opts(under_test)
    end
  end

  describe "handle_response/1" do
    test "handle_response/1 200" do
      response = {:ok, %{status: 200, body: "squirrel"}}
      assert {:ok, "squirrel"} == Helpers.handle_response(response)
    end

    test "handle_response/1 400" do
      body = %{"error" => %{"message" => "squirrel"}}
      response = {:ok, %{status: 400, body: body}}
      assert {:error, "Bad Request: squirrel"} == Helpers.handle_response(response)
    end

    test "handle_response/1 401" do
      response = {:ok, %{status: 401}}

      assert {:error, "Invalid Credentials: Please check your api_key and secret"} ==
               Helpers.handle_response(response)
    end

    test "handle_response/1 403" do
      response = {:ok, %{status: 403}}

      assert {:error, "Invalid Credentials: Please check your api_key and secret"} ==
               Helpers.handle_response(response)
    end

    test "handle_response/1 404" do
      response = {:ok, %{status: 404}}
      assert {:error, "Resource not found"} == Helpers.handle_response(response)
    end

    test "handle_response/1 420" do
      response = {:ok, %Tesla.Env{status: 420, headers: []}}

      assert {:error, "Your rate limit will be reset on unknown date"} ==
               Helpers.handle_response(response)
    end

    test "handle_response/1 420 with header set" do
      response =
        {:ok, %Tesla.Env{status: 420, headers: [{"x-featureratelimit-reset", "squirrel"}]}}

      assert {:error, "Your rate limit will be reset on squirrel"} ==
               Helpers.handle_response(response)
    end

    test "handle_response/1 500" do
      response = {:ok, %{status: 500, body: "squirrel"}}
      assert {:error, "General Error: squirrel"} == Helpers.handle_response(response)
    end

    test "handle_response/1 419" do
      response = {:ok, %{status: 419, body: "squirrel"}}
      assert {:error, "squirrel"} == Helpers.handle_response(response)
    end

    test "handle_response/1 755" do
      response = {:ok, %{status: 755}}

      assert {:error, "Unhandled response from Cloudinary %{status: 755}"} ==
               Helpers.handle_response(response)
    end
  end

  describe "handle_json_response/1" do
    test "handle_json_response/1 200" do
      response = {:ok, %{status: 200, body: Jason.encode!("squirrel")}}
      assert {:ok, "squirrel"} == Helpers.handle_json_response(response)
    end

    test "handle_json_response/1 400" do
      body =
        %{"error" => %{"message" => "squirrel"}}
        |> Jason.encode!()

      response = {:ok, %{status: 400, body: body}}
      assert {:error, "Bad Request: squirrel"} == Helpers.handle_json_response(response)
    end

    test "handle_json_response/1 401" do
      response = {:ok, %{status: 401}}

      assert {:error, "Invalid Credentials: Please check your api_key and secret"} ==
               Helpers.handle_json_response(response)
    end

    test "handle_json_response/1 403" do
      response = {:ok, %{status: 403}}

      assert {:error, "Invalid Credentials: Please check your api_key and secret"} ==
               Helpers.handle_json_response(response)
    end

    test "handle_json_response/1 404" do
      response = {:ok, %{status: 404}}
      assert {:error, "Resource not found"} == Helpers.handle_json_response(response)
    end

    test "handle_json_response/1 420" do
      response = {:ok, %Tesla.Env{status: 420, headers: []}}

      assert {:error, "Your rate limit will be reset on unknown date"} ==
               Helpers.handle_json_response(response)
    end

    test "handle_json_response/1 420 with header set" do
      response = {
        :ok,
        %Tesla.Env{
          status: 420,
          headers: [{"x-featureratelimit-reset", "squirrel"}]
        }
      }

      assert {:error, "Your rate limit will be reset on squirrel"} ==
               Helpers.handle_json_response(response)
    end

    test "handle_json_response/1 500" do
      response = {:ok, %{status: 500, body: "squirrel"}}
      assert {:error, "General Error: squirrel"} == Helpers.handle_json_response(response)
    end

    test "handle_json_response/1 419" do
      response = {:ok, %{status: 419, body: "squirrel"}}
      assert {:error, "squirrel"} == Helpers.handle_json_response(response)
    end
  end
end
