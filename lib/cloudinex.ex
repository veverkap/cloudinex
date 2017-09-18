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
  alias Cloudinex.Helpers
  alias Mix.Project
  import Cloudinex.Validation

  plug Tesla.Middleware.BaseUrl, base_url()
  plug Tesla.Middleware.BasicAuth, username: Helpers.api_key(),
                                   password: Helpers.secret()
  plug Tesla.Middleware.JSON
  plug Cloudinex.Middleware, enabled: Helpers.debug?()
  adapter Tesla.Adapter.Hackney

  @doc """
    Returns current version of library from Mix file
  """
  @spec version() :: String.t
  def version, do: Project.config[:version]
  @valid_moderation_types ~w(manual webpurify aws_rek metascan)
  @valid_moderation_statuses ~w(pending approved rejected)

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
    %{"bandwidth" => %{"limit" => 6442450944, "usage" => 6357564,
    "used_percent" => 0.1}, "derived_resources" => 174,
    "last_updated" => "2017-09-17",
    "objects" => %{"limit" => 125000, "usage" => 256, "used_percent" => 0.2},
    "plan" => "Free", "requests" => 248, "resources" => 82,
    "storage" => %{"limit" => 2671771648, "usage" => 29788466,
    "used_percent" => 1.11},
    "transformations" => %{"limit" => 7500, "usage" => 78,
    "used_percent" => 1.04}}

    iex> a.bandwidth.limit
    6442450944
    ```

    [API Docs](http://cloudinary.com/documentation/admin_api#usage_report)
  """
  @spec usage() :: map
  def usage do
    client()
    |> get("/usage")
    |> Helpers.handle_bang_response
  end

  @doc """
    Returns available resource types

    ```elixir
    iex> Cloudinex.resource_types
    {:ok, %{"resource_types" => ["image"]}}
    ```
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

  @doc """
    List resources in moderation queues

    * `:moderation_type` - (String: "manual", "webpurify", "aws_rek", or "metascan"). Type of image moderation queue to list.
    * `:status` - (String: "pending", "approved", "rejected"). Moderation status of resources.

    * `:resource_type` - Optional (String, default: image). The type of file. Possible values: image, raw, video. Relevant as a parameter only when using the SDKs (the resource type is included in the endpoint URL for direct calls to the HTTP API). Note: Use the video resource type for all video resources as well as for audio files, such as .mp3.
    * `:max_results` - Optional. (Integer, default=10. maximum=500). Max number of resources to return.
    * `:next_cursor` - Optional. When a listing request has more results to return than max_results, the next_cursor value is returned as part of the response. You can then specify this value as the next_cursor parameter of the following listing request.
    * `:direction` - Optional. (String/Integer, "asc" (or 1), "desc" (or -1), default: "desc" by creation date). Control the order of returned resources.
    * `:tags` - Optional (Boolean, default: false). If true, include the list of tag names assigned each resource.
    * `:context` - Optional (Boolean, default: false). If true, include key-value pairs of context associated with each resource.
    * `:moderations` - Optional (Boolean, default: false). If true, include image moderation status of each listed resource.

    [API Docs](http://cloudinary.com/documentation/admin_api#list_resources_in_moderation_queues)
  """
  @spec resources_by_moderation(moderation_type :: String.t,
                                status :: String.t,
                                options :: Keyword.t) :: map
  def resources_by_moderation(moderation_type, status, options \\ [])
    when moderation_type in @valid_moderation_types
    and status in @valid_moderation_statuses do
    {resource_type, options} = Keyword.pop(options, :resource_type, "image")

    url = "/resources/#{resource_type}/moderations/#{moderation_type}/#{status}"

    client()
    |> get(url, query: options)
    |> Helpers.handle_response
  end

  @doc """
    Details of a single resource

    Return details of the requested resource as well as all its derived resources.
    Note that if you only need details about the original resource, you can also
    use the upload or explicit methods, which are not rate limited.

    * `:public_id` - Required. (String). The public ID of the resource
    * `:resource_type` - Optional (String, default: image). The type of file. Possible values: image, raw, video. Relevant as a parameter only when using the SDKs (the resource type is included in the endpoint URL for direct calls to the HTTP API). Note: Use the video resource type for all video resources as well as for audio files, such as .mp3.
    * `:type` - Optional (String, default: upload). The storage type, for example, upload, private, authenticated, facebook, etc. Relevant as a parameter only when using the SDKs (the type is included in the endpoint URL for direct calls to the HTTP API).
    * `:colors` - Optional (Boolean, default: false). If true, include color information: predominant colors and histogram of 32 leading colors.
    * `:image_metadata` - Optional (Boolean, default: false). If true, include colorspace, ETag, IPTC, XMP, and detailed Exif metadata of the uploaded photo. Note: retrieves video metadata if the resource is a video file.
    * `:exif` - Optional (Boolean, default: false). If true, include image metadata (e.g., camera details). Deprecated. Please use image_metadata instead.
    * `:faces` - Optional (Boolean, default: false). If true, include a list of coordinates of detected faces.
    * `:pages` - Optional (Boolean, default: false). If true, report the number of pages in multi-page documents (e.g., PDF)
    * `:phash` - Optional (Boolean, default: false). If true, include the perceptual hash (pHash) of the uploaded photo for image similarity detection.
    * `:coordinates` - Optional (Boolean, default: false). If true, include previously specified custom cropping coordinates and faces coordinates.
    * `:max_results` - Optional. The number of derived images to return. Default=10. Maximum=100.
    * `:next_cursor` - Optional. If there are more derived images than max_results, the next_cursor value is returned as part of the response. You can then specify this value as the next_cursor parameter of the following listing request.

    [API Docs](http://cloudinary.com/documentation/admin_api#details_of_a_single_resource)
  """
  @spec resource(public_id :: String.t, options :: Keyword.t) :: map
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

  @doc """
    Update one or more of the attributes associated with a specified resource. Note that you can also update many attributes of an existing resource using the explicit method, which is not rate limited

    * `:public_id` - Required. (String). The public ID of the resource to update.
    * `:resource_type` - Optional (String, default: image). The type of file. Possible values: image, raw, video. Relevant as a parameter only when using the SDKs (the resource type is included in the endpoint URL for direct calls to the HTTP API). Note: Use the video resource type for all video resources as well as for audio files, such as .mp3.
    * `:type` - Optional (String, default: upload). The storage type, for example, upload, private, authenticated, facebook, etc. Relevant as a parameter only when using the SDKs (the type is included in the endpoint URL for direct calls to the HTTP API).
    * `:tags` - (Optional). A comma-separated list of tag names to assign to the uploaded image for later group reference.
    * `:context` - (Optional). A pipe separated list of key-value pairs of general textual context metadata to attach to an uploaded resource. The context values of uploaded files are available for fetching using the Admin API. For example: "alt=My image|caption=Profile Photo".
    * `:face_coordinates` - (Optional). List of coordinates of faces contained in an uploaded image. The given coordinates are used for cropping uploaded images using the face or faces gravity mode. The specified coordinates override the automatically detected faces. Each face is specified by the X & Y coordinates of the top left corner and the width & height of the face. The coordinates are comma separated while faces are concatenated with '|'. For example: "10,20,150,130|213,345,82,61".
    * `:custom_coordinates` - (Optional). Coordinates of an interesting region contained in an uploaded image. The given coordinates are used for cropping uploaded images using the custom gravity mode. The region is specified by the X & Y coordinates of the top left corner and the width & height of the region. For example: "85,120,220,310".
    * `:moderation_status` - (Optional. String: "approved", "rejected"). Manually set image moderation status or override previously automatically moderated images by approving or rejecting.
    * `:auto_tagging` (0.0 to 1.0 Decimal number) - (Optional). Whether to assign tags to an image according to detected scene categories with confidence score higher than the given value.
    * `:detection` - (Optional). Set to 'adv_face' to automatically extract advanced face attributes of photos using the Advanced Facial Attributes Detection add-on.
    * `:ocr` - (Optional). Set to 'adv_ocr' to extract all text elements in an image as well as the bounding box coordinates of each detected element using the OCR Text Detection and Extraction add-on.
    * `:raw_convert` - (Optional). Set to 'aspose' to automatically convert Office documents to PDF files and other image formats using the Aspose Document Conversion add-on.
    * `:categorization` - (Optional). Set to 'imagga_tagging' to automatically detect scene categories of photos using the Imagga Auto Tagging add-on.
    * `:background_removal` - (Optional). Set to 'remove_the_background' (or 'pixelz' - the new name of the company) to automatically clear the background of an uploaded photo using the Remove-The-Background Editing add-on.

    [API Docs](http://cloudinary.com/documentation/admin_api#update_resources)
  """
  @spec update_resource(public_id :: String.t, options :: Keyword.t) :: map
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

  @doc """
    Restore one or more resources from backup

    * `:resource_type` - Optional (String, default: image). The type of file. Possible values: image, raw, video. Relevant as a parameter only when using the SDKs (the resource type is included in the endpoint URL for direct calls to the HTTP API). Note: Use the video resource type for all video resources as well as for audio files, such as .mp3.
    * `:type` - Optional (String, default: upload). The storage type, for example, upload, private, authenticated, facebook, etc. Relevant as a parameter only when using the SDKs (the type is included in the endpoint URL for direct calls to the HTTP API).
    * `:public_ids` - The public IDs of (deleted or existing) backed up resources to restore. Reverts to the latest backed up version of the resource.

    [API Docs](http://cloudinary.com/documentation/admin_api#restore_resources)
  """
  @spec restore_resource(public_ids :: List.t, options :: Keyword.t) :: map
  def restore_resource(public_ids, options \\ []) do
    {resource_type, options} = Keyword.pop(options, :resource_type, "image")
    {type, _options} = Keyword.pop(options, :type, "upload")

    url = "/resources/#{resource_type}/#{type}/restore"

    client()
    |> post(url, %{public_ids: public_ids})
    |> Helpers.handle_response
  end

  @doc """
    Delete derived resources

    * `:derived_resource_ids` - Delete all derived resources with the given IDs (an array of up to 100 derived_resource_ids). The derived resource IDs are returned when calling the Details of a single resource method.

    [API Docs](http://cloudinary.com/documentation/admin_api#delete_derived_resources)
  """
  @spec delete_derived_resources(derived_resource_ids :: List.t, options :: Keyword.t) :: map
  def delete_derived_resources(derived_resource_ids, options \\ []) do
    query = [derived_resource_ids: derived_resource_ids]
          |> Keyword.merge(options)

    url = "/derived_resources"

    client()
    |> request(method: :delete, url: url, query: query)
    |> Helpers.handle_response
  end

  @doc """
    Deletes a single resource by its public id

    * `:resource_type` - Optional (String, default: image). The type of file. Possible values: image, raw, video. Relevant as a parameter only when using the SDKs (the resource type is included in the endpoint URL for direct calls to the HTTP API). Note: Use the video resource type for all video resources as well as for audio files, such as .mp3.
    * `:keep_original` - Optional (Boolean, default: false). If true, delete only the derived images of the matching resources.
    * `:invalidate` - Optional (Boolean, default: false). Whether to also invalidate the copies of the resource on the CDN. It usually takes a few minutes (although it might take up to an hour) for the invalidation to fully propagate through the CDN. There are also a number of other important considerations to keep in mind when invalidating files. Note that by default this parameter is not enabled: if you need this parameter enabled, please open a support request.
    * `:transformations` - Optional. Only the derived resources matching this array of transformation parameters will be deleted.
    * `:next_cursor` - Optional. When a deletion request has more than 1000 resources to delete, the response includes the partial boolean parameter set to true, as well as a next_cursor value. You can then specify this returned next_cursor value as the next_cursor parameter of the following deletion request.
  """
  @spec delete_resource(public_id :: String.t, options :: Keyword.t) :: map
  def delete_resource(public_id, options \\ []) when is_binary(public_id),
    do: delete_resources(%{public_ids: [public_id]}, options)

  @doc """
    Delete all resources, including derived resources, where the public ID starts with the given prefix (up to a maximum of 1000 original resources).

    * `:resource_type` - Optional (String, default: image). The type of file. Possible values: image, raw, video. Relevant as a parameter only when using the SDKs (the resource type is included in the endpoint URL for direct calls to the HTTP API). Note: Use the video resource type for all video resources as well as for audio files, such as .mp3.
    * `:keep_original` - Optional (Boolean, default: false). If true, delete only the derived images of the matching resources.
    * `:invalidate` - Optional (Boolean, default: false). Whether to also invalidate the copies of the resource on the CDN. It usually takes a few minutes (although it might take up to an hour) for the invalidation to fully propagate through the CDN. There are also a number of other important considerations to keep in mind when invalidating files. Note that by default this parameter is not enabled: if you need this parameter enabled, please open a support request.
    * `:transformations` - Optional. Only the derived resources matching this array of transformation parameters will be deleted.
    * `:next_cursor` - Optional. When a deletion request has more than 1000 resources to delete, the response includes the partial boolean parameter set to true, as well as a next_cursor value. You can then specify this returned next_cursor value as the next_cursor parameter of the following deletion request.
  """
  @spec delete_resources_by_prefix(prefix :: String.t, options :: Keyword.t) :: map
  def delete_resources_by_prefix(prefix, options \\ []) when is_binary(prefix),
    do: delete_resources(%{prefix: prefix}, options)
  @doc """
    Delete all resources (of the relevant resource type and type), including derived resources (up to a maximum of 1000 original resources).

    * `:resource_type` - Optional (String, default: image). The type of file. Possible values: image, raw, video. Relevant as a parameter only when using the SDKs (the resource type is included in the endpoint URL for direct calls to the HTTP API). Note: Use the video resource type for all video resources as well as for audio files, such as .mp3.
    * `:keep_original` - Optional (Boolean, default: false). If true, delete only the derived images of the matching resources.
    * `:invalidate` - Optional (Boolean, default: false). Whether to also invalidate the copies of the resource on the CDN. It usually takes a few minutes (although it might take up to an hour) for the invalidation to fully propagate through the CDN. There are also a number of other important considerations to keep in mind when invalidating files. Note that by default this parameter is not enabled: if you need this parameter enabled, please open a support request.
    * `:transformations` - Optional. Only the derived resources matching this array of transformation parameters will be deleted.
    * `:next_cursor` - Optional. When a deletion request has more than 1000 resources to delete, the response includes the partial boolean parameter set to true, as well as a next_cursor value. You can then specify this returned next_cursor value as the next_cursor parameter of the following deletion request.
  """
  @spec delete_all_resources(options :: Keyword.t) :: map
  def delete_all_resources(options \\ []),
    do: delete_resources(%{all: true}, options)
  @doc """
    Delete all resources (and their derivatives) with the given tag name (up to a maximum of 1000 original resources).

    * `:resource_type` - Optional (String, default: image). The type of file. Possible values: image, raw, video. Relevant as a parameter only when using the SDKs (the resource type is included in the endpoint URL for direct calls to the HTTP API). Note: Use the video resource type for all video resources as well as for audio files, such as .mp3.
    * `:keep_original` - Optional (Boolean, default: false). If true, delete only the derived images of the matching resources.
    * `:invalidate` - Optional (Boolean, default: false). Whether to also invalidate the copies of the resource on the CDN. It usually takes a few minutes (although it might take up to an hour) for the invalidation to fully propagate through the CDN. There are also a number of other important considerations to keep in mind when invalidating files. Note that by default this parameter is not enabled: if you need this parameter enabled, please open a support request.
    * `:transformations` - Optional. Only the derived resources matching this array of transformation parameters will be deleted.
    * `:next_cursor` - Optional. When a deletion request has more than 1000 resources to delete, the response includes the partial boolean parameter set to true, as well as a next_cursor value. You can then specify this returned next_cursor value as the next_cursor parameter of the following deletion request.

    [API Docs](http://cloudinary.com/documentation/admin_api#delete_resources_by_tags)
  """
  @spec delete_resources_by_tag(tag :: String.t, options :: Keyword.t) :: map
  def delete_resources_by_tag(tag, options \\ []),
    do: delete_resources(%{tag: tag}, options)

  @spec delete_resources(hash :: Map.t, options :: Keyword.t) :: map
  def delete_resources(hash, options \\ [])
  @doc """
    Delete all resources with the given public IDs (array of up to 100 public_ids).

    * `:resource_type` - Optional (String, default: image). The type of file. Possible values: image, raw, video. Relevant as a parameter only when using the SDKs (the resource type is included in the endpoint URL for direct calls to the HTTP API). Note: Use the video resource type for all video resources as well as for audio files, such as .mp3.
    * `:keep_original` - Optional (Boolean, default: false). If true, delete only the derived images of the matching resources.
    * `:invalidate` - Optional (Boolean, default: false). Whether to also invalidate the copies of the resource on the CDN. It usually takes a few minutes (although it might take up to an hour) for the invalidation to fully propagate through the CDN. There are also a number of other important considerations to keep in mind when invalidating files. Note that by default this parameter is not enabled: if you need this parameter enabled, please open a support request.
    * `:transformations` - Optional. Only the derived resources matching this array of transformation parameters will be deleted.
    * `:next_cursor` - Optional. When a deletion request has more than 1000 resources to delete, the response includes the partial boolean parameter set to true, as well as a next_cursor value. You can then specify this returned next_cursor value as the next_cursor parameter of the following deletion request.
  """
  def delete_resources(%{public_ids: public_ids}, options) when is_list(public_ids),
    do: delete_resources(%{public_ids:  Helpers.join_list(public_ids)}, options)
  def delete_resources(%{public_ids: public_ids}, options) when is_binary(public_ids),
    do: call_delete(options, [public_ids: public_ids])
  @doc """
    Delete all resources, including derived resources, where the public ID starts with the given prefix (up to a maximum of 1000 original resources).

    * `:resource_type` - Optional (String, default: image). The type of file. Possible values: image, raw, video. Relevant as a parameter only when using the SDKs (the resource type is included in the endpoint URL for direct calls to the HTTP API). Note: Use the video resource type for all video resources as well as for audio files, such as .mp3.
    * `:keep_original` - Optional (Boolean, default: false). If true, delete only the derived images of the matching resources.
    * `:invalidate` - Optional (Boolean, default: false). Whether to also invalidate the copies of the resource on the CDN. It usually takes a few minutes (although it might take up to an hour) for the invalidation to fully propagate through the CDN. There are also a number of other important considerations to keep in mind when invalidating files. Note that by default this parameter is not enabled: if you need this parameter enabled, please open a support request.
    * `:transformations` - Optional. Only the derived resources matching this array of transformation parameters will be deleted.
    * `:next_cursor` - Optional. When a deletion request has more than 1000 resources to delete, the response includes the partial boolean parameter set to true, as well as a next_cursor value. You can then specify this returned next_cursor value as the next_cursor parameter of the following deletion request.
  """
  def delete_resources(%{prefix: prefix}, options) when is_binary(prefix),
    do: call_delete(options, [prefix: prefix])
  @doc """
    Delete all resources (of the relevant resource type and type), including derived resources (up to a maximum of 1000 original resources).

    * `:resource_type` - Optional (String, default: image). The type of file. Possible values: image, raw, video. Relevant as a parameter only when using the SDKs (the resource type is included in the endpoint URL for direct calls to the HTTP API). Note: Use the video resource type for all video resources as well as for audio files, such as .mp3.
    * `:keep_original` - Optional (Boolean, default: false). If true, delete only the derived images of the matching resources.
    * `:invalidate` - Optional (Boolean, default: false). Whether to also invalidate the copies of the resource on the CDN. It usually takes a few minutes (although it might take up to an hour) for the invalidation to fully propagate through the CDN. There are also a number of other important considerations to keep in mind when invalidating files. Note that by default this parameter is not enabled: if you need this parameter enabled, please open a support request.
    * `:transformations` - Optional. Only the derived resources matching this array of transformation parameters will be deleted.
    * `:next_cursor` - Optional. When a deletion request has more than 1000 resources to delete, the response includes the partial boolean parameter set to true, as well as a next_cursor value. You can then specify this returned next_cursor value as the next_cursor parameter of the following deletion request.
  """
  def delete_resources(%{all: true}, options),
    do: call_delete(options, [all: true])
  @doc """
    Delete all resources (and their derivatives) with the given tag name (up to a maximum of 1000 original resources).

    * `:resource_type` - Optional (String, default: image). The type of file. Possible values: image, raw, video. Relevant as a parameter only when using the SDKs (the resource type is included in the endpoint URL for direct calls to the HTTP API). Note: Use the video resource type for all video resources as well as for audio files, such as .mp3.
    * `:keep_original` - Optional (Boolean, default: false). If true, delete only the derived images of the matching resources.
    * `:invalidate` - Optional (Boolean, default: false). Whether to also invalidate the copies of the resource on the CDN. It usually takes a few minutes (although it might take up to an hour) for the invalidation to fully propagate through the CDN. There are also a number of other important considerations to keep in mind when invalidating files. Note that by default this parameter is not enabled: if you need this parameter enabled, please open a support request.
    * `:transformations` - Optional. Only the derived resources matching this array of transformation parameters will be deleted.
    * `:next_cursor` - Optional. When a deletion request has more than 1000 resources to delete, the response includes the partial boolean parameter set to true, as well as a next_cursor value. You can then specify this returned next_cursor value as the next_cursor parameter of the following deletion request.
  """
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

  @doc """
    List tags for a resource type

    * `:resource_type` - Optional (String, default: image). The type of file for which to retrieve the tags. Possible values: image, raw, video. Relevant as a parameter only when using the SDKs (the resource type is included in the endpoint URL for direct calls to the HTTP API). Note: Use the video resource type for all video resources as well as for audio files, such as .mp3.
    * `:prefix` - Optional. Find all tags that start with the given prefix.
    * `:max_results` - Optional. Max number of tags to return. Default=10. Maximum=500.
    * `:next_cursor` - Optional. When a listing request has more results to return than max_results, the next_cursor value is returned as part of the response. You can then specify this value as the next_cursor parameter of the following listing request.

    [API Docs](http://cloudinary.com/documentation/admin_api#list_tags)
  """
  @spec tags(options :: Keyword.t) :: map
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

  @doc """
    Receive list of all transformations

    * `:max_results` - Optional. Max number of transformations to return. Default=10. Maximum=500.
    * `:next_cursor` - Optional. When a listing request has more results to return than max_results, the next_cursor value is returned as part of the response. You can then specify this value as the next_cursor parameter of the following listing request.

    [API Docs](http://cloudinary.com/documentation/admin_api#list_transformations)
  """
  @spec transformations(options :: Keyword.t) :: map
  def transformations(options \\ []) do
    url = "/transformations"

    keys = [:max_results, :next_cursor]

    options = options
              |> Keyword.take(keys)

    client()
    |> get(url, query: options)
    |> Helpers.handle_response
  end

  @doc """
    Receive details of a single transformation

    * `:max_results` - Optional. Max number of transformations to return. Default=10. Maximum=500.
    * `:next_cursor` - Optional. When a listing request has more results to return than max_results, the next_cursor value is returned as part of the response. You can then specify this value as the next_cursor parameter of the following listing request.

    [API Docs](http://cloudinary.com/documentation/admin_api#details_of_a_single_transformation)
  """
  @spec transformation(id :: String.t, options :: Keyword.t) :: map
  def transformation(id, options \\ []) do
    url = "/transformations/#{id}"

    keys = [:max_results, :next_cursor]

    options = options
              |> Keyword.take(keys)

    client()
    |> get(url, query: options)
    |> Helpers.handle_response
  end

  @doc """
    Delete transformation

    Note: Deleting a transformation also deletes all the derived images based on this transformation (up to 1000). The method returns an error if there are more than 1000 derived images based on this transformation.

    [API Docs](http://cloudinary.com/documentation/admin_api#delete_transformation)
  """
  @spec delete_transformation(id :: String.t, options :: Keyword.t) :: map
  def delete_transformation(id, options \\ []) do
    url = "/transformations/#{id}"

    client()
    |> delete(url, query: options)
    |> Helpers.handle_response
  end

  @doc """
    Updates transformation

    * `:allowed_for_strict` - Boolean. Whether this transformation is allowed when Strict Transformations are enabled.
    * `:unsafe_update` - Optional. Allows updating an existing named transformation without updating all associated derived images (the new settings of the named transformation only take effect from now on).

    [API Docs](http://cloudinary.com/documentation/admin_api#update_transformation)
  """
  @spec update_transformation(id :: String.t, options :: Keyword.t) :: map
  def update_transformation(id, options \\ []) do
    url = "/transformations/#{id}"

    client()
    |> request(method: :put, url: url, query: options)
    |> Helpers.handle_response
  end

  @doc """
    Create named transformation

    * `:name` - Name for transformation
    * `:transformation` - String representation of transformation parameters.

    [API Docs](http://cloudinary.com/documentation/admin_api#create_named_transformation)
  """
  @spec create_transformation(name :: String.t, transformation :: String.t) :: map
  def create_transformation(name, transformation) do
    url = "/transformations/#{name}"

    client()
    |> post(url, %{transformation: transformation})
    |> Helpers.handle_response
  end

  @doc """
    List all upload mappings by folder and its mapped template (URL).

    * `:max_results` - Optional. Max number of upload mappings to return. Default=10. Maximum=500.
    * `:next_cursor` - Optional. When a listing request has more results to return than max_results, the next_cursor value is returned as part of the response. You can then specify this value as the next_cursor parameter of the following listing request.

    [API Docs](http://cloudinary.com/documentation/admin_api#list_upload_mappings)
  """
  @spec upload_mappings(options :: Keyword.t) :: map
  def upload_mappings(options \\ []) do
    url = "/upload_mappings"

    keys = [:max_results, :next_cursor]

    options = options
              |> Keyword.take(keys)

    client()
    |> get(url, query: options)
    |> Helpers.handle_response
  end

  @doc """
    Details of a single upload mapping

    Retrieve the mapped template (URL) of a given upload mapping folder.

    [API Docs](http://cloudinary.com/documentation/admin_api#details_of_a_single_upload_mapping)
  """
  @spec upload_mapping(folder :: String.t) :: map
  def upload_mapping(folder) do
    url = "/upload_mappings/#{folder}"

    client()
    |> get(url)
    |> Helpers.handle_response
  end

  @doc """
    Create a new upload mapping folder and its template (URL).

    [API Docs](http://cloudinary.com/documentation/admin_api#create_an_upload_mapping)
  """
  @spec create_upload_mapping(folder :: String.t, template :: String.t) :: map
  def create_upload_mapping(folder, template) do
    url = "/upload_mappings"

    client()
    |> post(url, %{folder: folder, template: template})
    |> Helpers.handle_response
  end

  @doc """
    Delete an upload mapping by folder name.

    [API Docs](http://cloudinary.com/documentation/admin_api#delete_an_upload_mapping)
  """
  @spec delete_upload_mapping(folder :: String.t) :: map
  def delete_upload_mapping(folder) do
    url = "/upload_mappings/#{folder}"

    client()
    |> delete(url)
    |> Helpers.handle_response
  end

  @doc """
    Update an existing upload mapping folder with a new template (URL).

    Parameters:
    * `:folder` - The name of the mapped folder.
    * `:template` - The new URL to be mapped to the folder.

    [API Docs](http://cloudinary.com/documentation/admin_api#update_an_upload_mapping)
  """
  @spec update_upload_mapping(folder :: String.t, template :: String.t) :: map
  def update_upload_mapping(folder, template) do
    url = "/upload_mappings"

    query = %{folder: folder, template: template}

    client()
    |> request(method: :put, url: url, query: query)
    |> Helpers.handle_response
  end

  @doc """
    This method updates the access_mode of resources of a specific resource type (default = image) according to the defined conditions. When access_mode = 'authenticated', uploaded resources of type 'upload' behave as if they are of type 'authenticated'. The resource can later be made public by changing its access_mode to 'public', without having to update any image delivery URLs. In the case where public images are reverted to authenticated by changing their access_mode to 'authenticated', all the existing original and derived versions of the images are also invalidated on the CDN:

    Required Parameters:
    * `:access_mode` - The new access mode to be set ("public" or "authenticated").

    One of the following:
    * `:public_ids` - Update all resources with the given public IDs (array of up to 100 public_ids).
    prefix - Update all resources where the public ID starts with the given prefix (up to a maximum of 100 matching original resources).
    * `:tag` - Update all resources with the given tag (up to a maximum of 100 matching original resources).

    Optional Parameters:
    * `:resource_type` - Optional (String, default: image). The type of file. Possible values: image, raw, video. Relevant as a parameter only when using the SDKs (the resource type is included in the endpoint URL for direct calls to the HTTP API). Note: Use the video resource type for all video resources as well as for audio files, such as .mp3.
    * `:next_cursor` - Optional. When an update request has more than 100 resources to update, the response includes a next_cursor value. You can then specify this returned next_cursor value as the next_cursor parameter of the following update request.
  """
  @spec update_access_mode(hash :: Map.t, options :: Keyword.t) :: map
  def update_access_mode(hash, access_mode, options \\ [])
  def update_access_mode(%{public_ids: public_ids}, access_mode, options) when is_list(public_ids),
    do: call_update_access_mode(options, access_mode, [public_ids: public_ids])
  def update_access_mode(%{prefix: prefix}, access_mode, options) when is_binary(prefix),
    do: call_update_access_mode(options, access_mode, [prefix: prefix])
  def update_access_mode(%{tag: tag}, access_mode, options) when is_binary(tag),
    do: call_update_access_mode(options, access_mode, [tag: tag])

  defp call_update_access_mode(options, access_mode, query) do
    {resource_type, options} = Keyword.pop(options, :resource_type, "image")
    {type, options} = Keyword.pop(options, :type, "upload")

    url = "/resources/#{resource_type}/#{type}/update_access_mode"

    keys = [:public_ids, :prefix, :tag, :next_cursor, :access_mode]

    options = options
              |> Keyword.merge(query)
              |> Keyword.merge([access_mode: access_mode])
              |> remove_invalid_keys(keys)
              |> valid_member?(["public", "authenticated"], :access_mode)

    client()
    |> request(method: :put, url: url, query: options)
    |> Helpers.handle_response
  end

  @doc """
    Lists upload presets

    Parameters:
    * `:max_results` - Optional. Max number of upload presets to return. Default=10. Maximum=500.
    * `:next_cursor` - Optional. When a listing request has more results to return than max_results, the next_cursor value is returned as part of the response. You can then specify this value as the next_cursor parameter of the following listing request.

    [API Docs](http://cloudinary.com/documentation/admin_api#list_upload_presets)
  """
  @spec upload_presets(options :: Keyword.t) :: map
  def upload_presets(options \\ []) do
    url = "/upload_presets"

    client()
    |> get(url, query: options)
    |> Helpers.handle_response()
  end

  @doc """
    Retrieves the details of an upload preset.

    [API Docs](http://cloudinary.com/documentation/admin_api#details_of_a_single_upload_preset)
  """
  @spec upload_preset(preset_name :: String.t) :: map
  def upload_preset(preset_name) do
    url = "/upload_presets/#{preset_name}"

    client()
    |> get(url)
    |> Helpers.handle_response()
  end

  @doc """
    Create a new upload preset.

    Parameters:
    * `:name` - The name to assign to the upload preset.
    * `:unsigned` - Boolean. Whether this upload preset allows unsigned uploading to Cloudinary.
    * `:disallow_public_id` - Boolean. Whether this upload preset disables assigning a public_id in the image upload call.
    * `:settings` - The [upload actions](http://cloudinary.com/documentation/image_upload_api_reference#upload) to apply to the images uploaded with this preset.

    [API Docs](http://cloudinary.com/documentation/admin_api#create_an_upload_preset)
  """
  @spec create_upload_preset(name :: String.t, unsigned :: boolean,
                             disallow_public_id :: boolean,
                             settings :: Keyword.t) :: map
  def create_upload_preset(name, unsigned, disallow_public_id, settings \\ []) do
    url = "/upload_presets"

    settings = settings
               |> Keyword.merge([name: name, unsigned: unsigned,
                                 disallow_public_id: disallow_public_id])
    client()
    |> post(url, Helpers.unify(settings))
    |> Helpers.handle_response
  end

  @doc """
    Updates upload preset.

    Parameters:
    * `:name` - The name to assign to the upload preset.
    * `:unsigned` - Boolean. Whether this upload preset allows unsigned uploading to Cloudinary.
    * `:disallow_public_id` - Boolean. Whether this upload preset disables assigning a public_id in the image upload call.
    * `:settings` - The [upload actions](http://cloudinary.com/documentation/image_upload_api_reference#upload) to apply to the images uploaded with this preset.

    [API Docs](http://cloudinary.com/documentation/admin_api#update_an_upload_preset)
  """
  @spec update_upload_preset(name :: String.t, settings :: Keyword.t) :: map
  def update_upload_preset(name, settings \\ []) do
    url = "/upload_presets/#{name}"

    client()
    |> request(method: :put, url: url, query: settings)
    |> Helpers.handle_response
  end

  @doc """
    Deletes upload preset

    [API Docs](http://cloudinary.com/documentation/admin_api#delete_an_upload_preset)
  """
  @spec delete_upload_preset(id :: String.t, options :: Keyword.t) :: map
  def delete_upload_preset(id, options \\ []) do
    url = "/upload_presets/#{id}"

    client()
    |> delete(url, query: options)
    |> Helpers.handle_response
  end

  @doc """
    List all the root folders

    [API Docs](http://cloudinary.com/documentation/admin_api#list_root_folders)
  """
  @spec folders() :: map
  def folders do
    url = "/folders"

    client()
    |> get(url)
    |> Helpers.handle_response
  end

  @doc """
    Lists the name and path of all the subfolders of a given root folder.

    [API Docs](http://cloudinary.com/documentation/admin_api#list_subfolders)
  """
  @spec folders(root_folder :: String.t) :: map
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
