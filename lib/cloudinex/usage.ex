defmodule Cloudinex.Usage do
  @moduledoc """
  A custom type representing usage from [Cloudinary's API](http://cloudinary.com/documentation/admin_api#usage_report)
  """
  alias Cloudinex.{Helpers, Usage, UsageDetail}
  @typedoc """
  A custom type representing usage from [Cloudinary's API](http://cloudinary.com/documentation/admin_api#usage_report)
  """
  @type t :: %Usage{
    bandwidth: %UsageDetail{},
    derived_resources: integer,
    last_updated: String.t,
    objects: %UsageDetail{},
    plan: String.t,
    requests: integer,
    resources: integer,
    storage: %UsageDetail{},
    transformations: %UsageDetail{}
  }
  defstruct bandwidth: %UsageDetail{},
            derived_resources: 0,
            last_updated: "",
            objects: %UsageDetail{},
            plan: "Free",
            requests: 0,
            resources: 0,
            storage: %UsageDetail{},
            transformations: %UsageDetail{}

  def new(item) do
    usage_struct = struct(Usage, Helpers.atomize(item))

    %Usage{
      usage_struct |
        bandwidth:       UsageDetail.new(usage_struct.bandwidth),
        objects:         UsageDetail.new(usage_struct.objects),
        storage:         UsageDetail.new(usage_struct.storage),
        transformations: UsageDetail.new(usage_struct.transformations)
    }
  end
end
