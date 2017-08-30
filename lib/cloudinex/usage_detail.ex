defmodule Cloudinex.UsageDetail do
  @moduledoc """
  A custom type representing limit, usage and percentage
  """
  alias Cloudinex.{Helpers, UsageDetail}
  @typedoc """
  A custom type representing limit, usage and percentage
  """
  @type t :: %UsageDetail{limit: integer, usage: integer, used_percent: float}
  defstruct limit: 0, usage: 0, used_percent: 0.0

  def new(item) do
    struct(UsageDetail, Helpers.atomize(item))
  end
end
