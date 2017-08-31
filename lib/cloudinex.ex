defmodule Cloudinex do
  @moduledoc """
    Cloudinex is an Elixir wrapper around the Cloudinary API.

    The administrative API allows full control of all uploaded raw files and
    images, fetched social profile pictures, generated transformations and more.

    The API is accessed using HTTPS to endpoints in the following format:

    `https://api.cloudinary.com/v1_1/:cloud_name/:action`

    Authentication is done using Basic Authentication over secure HTTP. Your
    Cloudinary API Key and API Secret are used for the authentication and can be
    found [here](https://cloudinary.com/console).  Configuration
    is handled via application variables:

    ```elixir
    config :cloudinex,
          debug: false, #optional
          base_url: "https://api.cloudinary.com/v1_1/",
          api_key: "YOUR_API_KEY",
          secret: "YOUR_API_SECRET",
          cloud_name: "YOUR_CLOUD_NAME"
    ```

    Request parameters are appended to the URL by passing in a keyword list of
    options.

    All responses are decoded from JSON into Elixir maps.

    [Cloudinary Documentation](http://cloudinary.com/documentation)
  """
  use Tesla, docs: false
  require Logger
  alias Cloudinex.{Helpers, Usage}
  import Cloudinex.Validation

  plug Tesla.Middleware.BaseUrl, base_url()
  plug Tesla.Middleware.BasicAuth, username: Application.get_env(:cloudinex, :api_key),
                                   password: Application.get_env(:cloudinex, :secret)
  plug Tesla.Middleware.JSON
  plug Cloudinex.Middleware, enabled: Application.get_env(:cloudinex, :debug, false)
  adapter Tesla.Adapter.Hackney

  @doc """
    Test the reachability of the Cloudinary API with the ping method.

    ```elixir
    iex> Cloudinex.ping
    {:ok, %{"status" => "ok"}}
    ```

    [API Docs](http://cloudinary.com/documentation/admin_api#ping_cloudinary)
  """
  @spec ping() :: {atom, map}
  def ping do
    client()
    |> get("/ping")
    |> Helpers.handle_response
  end

  @doc """
    Test the reachability of the Cloudinary API with the ping method.

    ```elixir
    iex> Cloudinex.ping!
    %{"status" => "ok"}
    ```

    [API Docs](http://cloudinary.com/documentation/admin_api#ping_cloudinary)
  """
  @spec ping!() :: map
  def ping! do
    client()
    |> get("/ping")
    |> Helpers.handle_bang_response
  end

  @doc """
    Get a report on the status of your Cloudinary account usage details, including
    storage, bandwidth, requests, number of resources, and add-on usage. Note that
    numbers are updated periodically

    ```elixir
    iex> a = Cloudinex.usage
    %Cloudinex.Usage{
      bandwidth: %Cloudinex.UsageDetail{limit: 6442450944, usage: 3927186, used_percent: 0.06},
      derived_resources: 167,
      last_updated: "2017-08-29",
      objects: %Cloudinex.UsageDetail{limit: 125000, usage: 230, used_percent: 0.18},
      plan: "Free",
      requests: 230,
      resources: 63,
      storage: %Cloudinex.UsageDetail{limit: 2671771648, usage: 23139073, used_percent: 0.87},
      transformations: %Cloudinex.UsageDetail{limit: 7500, usage: 39, used_percent: 0.52}}

    iex> a.bandwidth.limit
    6442450944
    ```

    [API Docs](http://cloudinary.com/documentation/admin_api#usage_report)
  """
  @spec usage() :: %Usage{}
  def usage do
    client()
    |> get("/usage")
    |> Helpers.handle_bang_response
    |> Usage.new
  end

  @doc """
    Returns available resource types

    ```elixir
    iex> Cloudinex.resource_types
    {:ok, %{"resource_types" => ["image"]}}
  """
  @spec resource_types() :: {atom, map}
  def resource_types do
    client()
    |> get("/resources")
    |> Helpers.handle_response
  end

  @doc """
    List resources by parameters

    * `:resource_type` - Optional (String, default: image). The type of file. Possible values: image, raw, video. Relevant as a parameter only when using the SDKs (the resource type is included in the endpoint URL for direct calls to the HTTP API). Note: Use the video resource type for all video resources as well as for audio files, such as .mp3.
    * `:type` - Optional (String, default: all). The storage type, for example, upload, private, authenticated, facebook, etc. Relevant as a parameter only when using the SDKs (the type is included in the endpoint URL for direct calls to the HTTP API).
    * `:prefix` - Optional. (String). Find all resources with a public ID that starts with the given prefix. The resources are sorted by public ID in the response.
    * `:public_ids` - Optional. (String, comma-separated list of public IDs). List resources with the given public IDs (up to 100).
    * `:max_results` - Optional. (Integer, default=10. maximum=500). Max number of resources to return.
    * `:next_cursor` - Optional. When a listing request has more results to return than max_results, the next_cursor value is returned as part of the response. You can then specify this value as the next_cursor parameter of the following listing request.
    * `:start_at` - Optional. (Timestamp string). List resources that were created since the given timestamp. Supported if no prefix or public IDs were specified.
    * `:direction` - Optional. (String/Integer, "asc" (or 1), "desc" (or -1), default: "desc" according to the created_at date). Control the order of returned resources. Note that if a prefix is specified, this parameter is ignored and the results are sorted by public ID.
    * `:tags` - Optional (Boolean, default: false). If true, include the list of tag names assigned each resource.
    * `:context` - Optional (Boolean, default: false). If true, include key-value pairs of context associated with each resource.
    * `:moderations` - Optional (Boolean, default: false). If true, include image moderation status of each listed resource.

    ```elixir
    iex> Cloudinex.resources
    {:ok,
     %{"next_cursor" => "c3e05e720779a7aba3953abfc1017e5b",
       "resources" => [
        %{"bytes" => 745895,
          "created_at" => "2017-08-29T20:30:06Z",
          "format" => "png",
          "height" => 720,
          "public_id" => "zfqp6sjepkrkyrxnflpr",
          "resource_type" => "image",
          "secure_url" => "https://res.cloudinary.com/demo/image/upload/v1504038606/zfqp6sjepkrkyrxnflpr.png",
          "type" => "upload",
          "url" => "http://res.cloudinary.com/demo/image/upload/v1504038606/zfqp6sjepkrkyrxnflpr.png",
          "version" => 1504038606,
          "width" => 720}
        ]
      }
    }
    ```
    [API Docs](http://cloudinary.com/documentation/admin_api#list_resources)
  """
  @spec resources(options :: Keyword.t) :: map
  def resources(options \\ []) do
    {resource_type, options} = Keyword.pop(options, :resource_type, "image")
    {type, options}          = Keyword.pop(options, :type)

    url = case type do
      nil ->
        "/resources/#{resource_type}"
      type ->
        "/resources/#{resource_type}/#{type}"
    end

    keys = [:context, :direction, :max_results, :moderations, :next_cursor,
            :prefix, :public_ids, :start_at, :tags]

    options = options
              |> Keyword.take(keys)

    client()
    |> get(url, query: options)
    |> Helpers.handle_response
  end

  @doc """
    Retrieve a list of resources with a specified tag. This method does not return deleted resources even if they have been backed up.

    * `:resource_type` - Optional (String, default: image). The type of files for which you want to retrieve tags. Possible values: image, raw, video. Note: Use the video resource type for all video resources as well as for audio files, such as .mp3. Relevant as a parameter only when using the SDKs (the resource type is included in the endpoint URL for direct calls to the HTTP API).
    * `:max_results` - Optional. (Integer, default=10. maximum=500). Max number of resources to return.
    * `:next_cursor` - Optional. When a listing request has more results to return than max_results, the next_cursor value is returned as part of the response. You can then specify this value as the next_cursor parameter of the following listing request.
    * `:direction` - Optional. (String/Integer, "asc" (or 1), "desc" (or -1), default: "desc" by creation date). Control the order of returned resources.
    * `:tags` - Optional (Boolean, default: false). If true, include the list of tag names assigned each resource.
    * `:context` - Optional (Boolean, default: false). If true, include key-value pairs of context associated with each resource.
    * `:moderations` - Optional (Boolean, default: false). If true, include image moderation status of each listed resource.

    [API Docs](http://cloudinary.com/documentation/admin_api#list_resources_by_tag)
  """
  @spec resources_by_tag(tag :: String.t, options :: Keyword.t) :: map
  def resources_by_tag(tag, options \\ []) do
    {resource_type, options} = Keyword.pop(options, :resource_type, "image")

    url = "/resources/#{resource_type}/tags/#{tag}"

    keys = [:max_results, :next_cursor, :direction, :tags, :context, :moderations]

    options = options
              |> Keyword.take(keys)

    client()
    |> get(url, query: options)
    |> Helpers.handle_response
  end

  @doc """
    Retrieve a list of resources with a specified context key. This method does not return deleted resources even if they have been backed up.
    * `:resource_type` - Optional (String, default: image). The type of file. Possible values: image, raw, video. Relevant as a parameter only when using the SDKs (the resource type is included in the endpoint URL for direct calls to the HTTP API). Note: Use the video resource type for all video resources as well as for audio files, such as .mp3.
    * `:value` - Optional. (String). Only resources with this value for the context key are returned. If this parameter is not provided, all resources with the given context key are returned, regardless of the actual value of the key.
    * `:max_results` - Optional. (Integer, default=10. maximum=500). Max number of resources to return.
    * `:next_cursor` - Optional. When a listing request has more results to return than max_results, the next_cursor value is returned as part of the response. You can then specify this value as the next_cursor parameter of the following listing request.
    * `:direction` - Optional. (String/Integer, "asc" (or 1), "desc" (or -1), default: "desc" by creation date). Control the order of returned resources.
    * `:tags` - Optional (Boolean, default: false). If true, include the list of tag names assigned each resource.
    * `:context `- Optional (Boolean, default: false). If true, include all key-value pairs of context associated with each resource.

    [API Docs](http://cloudinary.com/documentation/admin_api#list_resources_by_context)
  """
  @spec resources_by_context(key :: String.t, value :: String.t, options :: Keyword.t) :: map
  def resources_by_context(key, value \\ nil, options \\ []) do
    {resource_type, options} = Keyword.pop(options, :resource_type, "image")

    url = case value do
      nil ->
        "/resources/#{resource_type}/context/?key=#{key}"
      value ->
        "/resources/#{resource_type}/context/?key=#{key}&value=#{value}"
    end

    keys = [:max_results, :next_cursor, :direction, :tags, :context]

    options = options
              |> Keyword.take(keys)

    client()
    |> get(url, query: options)
    |> Helpers.handle_response
  end

  def resources_by_moderation(type, status, options \\ []) do
    {resource_type, options} = Keyword.pop(options, :resource_type, "image")

    valid_types = ["manual", "webpurify", "aws_rek", "metascan"]
    valid_status = ["pending", "approved", "rejected"]

    type = case Enum.member?(valid_types, type) do
      true -> type
      false -> "manual"
    end

    status = case Enum.member?(valid_status, status) do
      true -> status
      false -> "pending"
    end

    url = "/resources/#{resource_type}/moderations/#{type}/#{status}"

    client()
    |> get(url, query: options)
    |> Helpers.handle_response
  end

  def resource(public_id, options \\ []) do
    {resource_type, options} = Keyword.pop(options, :resource_type, "image")
    {type, options} = Keyword.pop(options, :type, "upload")

    url = "/resources/#{resource_type}/#{type}/#{public_id}"

    keys = [:colors, :exif, :faces, :image_metadata, :pages, :phash,
            :coordinates, :max_results]

    options = options
              |> Keyword.take(keys)

    client()
    |> get(url, query: options)
    |> Helpers.handle_response
  end

  def update_resource(public_id, options \\ []) do
    {resource_type, options} = Keyword.pop(options, :resource_type, "image")
    {type, options} = Keyword.pop(options, :type, "upload")

    url = "/resources/#{resource_type}/#{type}/#{public_id}"

    keys = [:tags, :context, :face_coordinates, :custom_coordinates,
            :moderation_status, :auto_tagging, :detection, :ocr, :raw_convert,
            :categorization, :background_removal, :notification_url]

    options = options
              |> remove_invalid_keys(keys)
              |> parse_keyword(:face_coordinates, &Helpers.map_coordinates/1)
              |> parse_keyword(:custom_coordinates, &Helpers.map_coordinates/1)
              |> parse_keyword(:tags, &Helpers.join_list/1)
              |> parse_keyword(:context, &Helpers.map_context/1)
              |> valid_member?(["approved", "rejected"], :moderation_status)
              |> valid_member?(["remove_the_background", "pixelz"], :background_removal)
              |> valid_option?(:detection, "adv_face")
              |> valid_option?(:ocr, "adv_ocr")
              |> valid_option?(:raw_convert, "aspose")
              |> valid_option?(:categorization, "imagga_tagging")
              |> valid_float_range?(:auto_tagging, 0.0, 1.0)

    client()
    |> post(url, Helpers.unify(options))
    |> Helpers.handle_response
  end

  def restore(public_ids, options \\ []) do
    {resource_type, options} = Keyword.pop(options, :resource_type, "image")
    {type, _options} = Keyword.pop(options, :type, "upload")

    url = "/resources/#{resource_type}/#{type}/restore"

    client()
    |> post(url, %{public_ids: public_ids})
    |> Helpers.handle_response
  end

  def delete_resource(public_id, options \\ []) when is_binary(public_id),
    do: delete_resources(%{public_ids: [public_id]}, options)

  def delete_derived_resources(derived_resource_ids, options \\ []) do
    query = [derived_resource_ids: derived_resource_ids]
          |> Keyword.merge(options)

    url = "/derived_resources"

    client()
    |> request(method: :delete, url: url, query: query)
    |> Helpers.handle_response
  end

  def delete_resources_by_prefix(prefix, options \\ []) when is_binary(prefix),
    do: delete_resources(%{prefix: prefix}, options)
  def delete_all_resources(options \\ []),
    do: delete_resources(%{all: true}, options)
  def delete_resources_by_tag(tag, options \\ []),
    do: delete_resources(%{tag: tag}, options)

  def delete_resources(hash, options \\ [])
  def delete_resources(%{public_ids: public_ids}, options) when is_list(public_ids),
    do: delete_resources(%{public_ids:  Helpers.join_list(public_ids)}, options)
  def delete_resources(%{public_ids: public_ids}, options) when is_binary(public_ids),
    do: call_delete(options, [public_ids: public_ids])
  def delete_resources(%{prefix: prefix}, options) when is_binary(prefix),
    do: call_delete(options, [prefix: prefix])
  def delete_resources(%{all: true}, options),
    do: call_delete(options, [all: true])
  def delete_resources(%{tag: tag}, options),
    do: call_delete(options, [tag: tag])

  defp call_delete(options, query) do
    {resource_type, options} = Keyword.pop(options, :resource_type, "image")
    {type, options} = Keyword.pop(options, :type, "upload")
    {tag, query} = Keyword.pop(query, :tag)

    keys = [:keep_original, :next_cursor, :invalidate, :transformations]
    query = options
            |> remove_invalid_keys(keys)
            |> Keyword.merge(query)

    url = case tag do
      nil -> "/resources/#{resource_type}/#{type}"
      tag -> "/resources/#{resource_type}/tags/#{tag}"
    end

    client()
    |> request(method: :delete, url: url, query: query)
    |> Helpers.handle_response
  end

  def tags(options \\ []) do
    {resource_type, options} = Keyword.pop(options, :resource_type, "image")

    url = "/tags/#{resource_type}"

    keys = [:prefix, :max_results, :next_cursor]

    options = options
              |> Keyword.take(keys)

    client()
    |> get(url, query: options)
    |> Helpers.handle_response
  end

  def transformations(options \\ []) do
    url = "/transformations"

    keys = [:max_results, :next_cursor]

    options = options
              |> Keyword.take(keys)

    client()
    |> get(url, query: options)
    |> Helpers.handle_response
  end

  def transformation(id, options \\ []) do
    url = "/transformations/#{id}"

    keys = [:max_results, :next_cursor]

    options = options
              |> Keyword.take(keys)

    client()
    |> get(url, query: options)
    |> Helpers.handle_response
  end

  def delete_transformation(id, options \\ []) do
    url = "/transformations/#{id}"

    client()
    |> delete(url, query: options)
    |> Helpers.handle_response
  end

  def update_transformation(id, options \\ []) do
    url = "/transformations/#{id}"

    client()
    |> request(method: :put, url: url, query: options)
    |> Helpers.handle_response
  end

  def create_transformation(name, transformation) do
    url = "/transformations/#{name}"

    client()
    |> post(url, %{transformation: transformation})
    |> Helpers.handle_response
  end

  def upload_mappings(options \\ []) do
    url = "/upload_mappings"

    keys = [:max_results, :next_cursor]

    options = options
              |> Keyword.take(keys)

    client()
    |> get(url, query: options)
    |> Helpers.handle_response
  end

  def upload_mapping(folder) do
    url = "/upload_mappings/#{folder}"

    client()
    |> get(url)
    |> Helpers.handle_response
  end

  def create_upload_mapping(folder, template) do
    url = "/upload_mappings"

    client()
    |> post(url, %{folder: folder, template: template})
    |> Helpers.handle_response
  end

  def delete_upload_mapping(folder) do
    url = "/upload_mappings/#{folder}"

    client()
    |> delete(url)
    |> Helpers.handle_response
  end

  def update_upload_mapping(folder, template) do
    url = "/upload_mappings"

    query = %{folder: folder, template: template}

    client()
    |> request(method: :put, url: url, query: query)
    |> Helpers.handle_response
  end

  def update_access_mode_by_public_ids(public_ids, access_mode, options \\ []) do
    {resource_type, options} = Keyword.pop(options, :resource_type, "image")

    url = "/resources/#{resource_type}/upload/update_access_mode"

    keys = [:public_ids, :access_mode, :next_cursor]

    options = options
              |> Keyword.merge([public_ids: public_ids, access_mode: access_mode])
              |> remove_invalid_keys(keys)
              |> valid_member?(["public", "authenticated"], :access_mode)

    client()
    |> request(method: :put, url: url, query: options)
    |> Helpers.handle_response
  end

  def upload_presets(options \\ []) do
    url = "/upload_presets"

    client()
    |> get(url, query: options)
    |> Helpers.handle_response()
  end

  def upload_preset(preset_name) do
    url = "/upload_presets/#{preset_name}"

    client()
    |> get(url)
    |> Helpers.handle_response()
  end

  def create_upload_preset(name, unsigned, disallow_public_id, settings \\ []) do
    url = "/upload_presets"

    settings = settings
               |> Keyword.merge([name: name, unsigned: unsigned,
                                 disallow_public_id: disallow_public_id])
    client()
    |> post(url, Helpers.unify(settings))
    |> Helpers.handle_response
  end

  def update_upload_preset(name, settings \\ []) do
    url = "/upload_presets/#{name}"

    client()
    |> request(method: :put, url: url, query: settings)
    |> Helpers.handle_response
  end

  def delete_upload_preset(id, options \\ []) do
    url = "/upload_presets/#{id}"

    client()
    |> delete(url, query: options)
    |> Helpers.handle_response
  end

  def folders do
    url = "/folders"

    client()
    |> get(url)
    |> Helpers.handle_response
  end

  def folders(root_folder) do
    url = "/folders/#{root_folder}"

    client()
    |> get(url)
    |> Helpers.handle_response
  end

  defp client do
    Tesla.build_client []
  end

  defp base_url do
    "#{Application.get_env(:cloudinex, :base_url)}#{Application.get_env(:cloudinex, :cloud_name)}"
  end
end
