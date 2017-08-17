defmodule Cloudinex.TestHelpers do
  @moduledoc false
  def load_fixture(fixture_name) do
    File.read!("./test/fixtures/#{fixture_name}.json")
  end
end
