ExUnit.start()
Application.ensure_all_started(:bypass)
Application.put_env(:cloudinex, :cloud_name, "demo")

defmodule Cloudinex.TestHelper do
  def load_fixture(fixture_name) do
    File.read!("./test/fixtures/#{fixture_name}.json")
  end
end
