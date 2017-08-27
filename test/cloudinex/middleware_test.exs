defmodule Cloudinex.MiddlewareTest do
  @moduledoc false
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  defmodule Client do
    use Tesla
    plug Cloudinex.Middleware

    adapter fn (env) ->
      {status, body} = case env.url do
        "/connection-error" -> raise %Tesla.Error{message: "adapter error: :econnrefused", reason: :econnrefused}
        "/redirect"         -> {301, "moved"}
      end
      %{env | status: status, body: body}
    end
  end

  describe "call with not enabled" do
    test "not enabled with error" do
      env = %Tesla.Env{url: "apple.com", method: :get, status: 500}
      log = capture_log(fn ->
        Cloudinex.Middleware.call(env, [], enabled: false)
      end)
      assert log =~ "error"
      assert log =~ "apple.com"
      assert log =~ "GET"
    end

    test "not enabled with success" do
      env = %Tesla.Env{url: "apple.com", method: :put, status: 200}
      log = capture_log(fn ->
        Cloudinex.Middleware.call(env, [], enabled: false)
      end)
      assert log =~ "200"
      assert log =~ "apple.com"
      assert log =~ "PUT"
    end
  end

  describe "call with enabled" do
    test "not enabled with error" do
      env = %Tesla.Env{
        url: "apple.com",
        method: :get,
        status: 500,
        headers: %{"accepts" => "json"},
        query: [one: "two"],
        opts: [slim: "none"],
        body: "{'tango': 'cash'}"
      }
      log = capture_log(fn ->
        Cloudinex.Middleware.call(env, [], enabled: true)
      end)
      assert log =~ "apple.com"
      assert log =~ "GET"
      assert log =~ "tango"
      assert log =~ "Query Param"
    end
  end

  describe "connection error" do
    test "connection error" do
      _ = capture_log(fn ->
        assert_raise Tesla.Error, fn -> Client.get("/connection-error") end
      end)
    end
  test "redirect" do
    log = capture_log(fn -> Client.get("/redirect") end)
    assert log =~ "/redirect"
    assert log =~ "301"
  end
  end
end
