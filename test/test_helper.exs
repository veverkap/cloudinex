ExUnit.start()
Application.ensure_all_started(:bypass)
Application.put_env(:cloudinex, :cloud_name, "demo")

defmodule Cloudinex.TestHelper do
  def load_fixture(fixture_name) do
    File.read!("./test/fixtures/#{fixture_name}.json")
  end

  def expect_json(bypass, fun) do
    Bypass.expect(bypass, fn conn ->
      conn =
        Plug.Conn.put_resp_header(
          conn,
          "content-type",
          "application/json"
        )

      fun.(conn)
    end)
  end
end
