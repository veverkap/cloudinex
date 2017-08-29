defmodule Cloudinex do
  @moduledoc false
  use Tesla, docs: false
  require Logger
  alias Cloudinex.Helpers
  import Cloudinex.Validation

  plug Tesla.Middleware.BaseUrl, base_url()
  plug Tesla.Middleware.BasicAuth, username: Application.get_env(:cloudinex, :api_key),
                                   password: Application.get_env(:cloudinex, :secret)
  plug Cloudinex.Middleware, enabled: false
  adapter Tesla.Adapter.Hackney

  @doc """
  Pings the Cloudinary endpoints
  """
  def ping do
    client()
    |> get("/ping")
    |> Helpers.handle_response
  end

  @doc """
  Returns information about account usage
  """
  def usage do
    client()
    |> get("/usage")
    |> Helpers.handle_response
  end

  def resource_types do
    client()
    |> get("/resources")
    |> Helpers.handle_response
  end

  def resources(options \\ []) do
    {resource_type, options} = Keyword.pop(options, :resource_type, "image")
    {type, options} = Keyword.pop(options, :type)

    url = case type do
      nil ->
        "/resources/#{resource_type}"
      type ->
        "/resources/#{resource_type}/#{type}"
    end

    keys = [:prefix, :public_ids, :max_results, :next_cursor, :start_at,
            :direction, :tags, :context, :moderations]

    options = options
              |> Keyword.take(keys)

    client()
    |> get(url, query: options)
    |> Helpers.handle_response
  end

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

  def upload(item, opts \\ %{}) when is_binary(item) do
    case item do
      "http://" <> _rest  -> item |> upload_url(opts)
      "https://" <> _rest -> item |> upload_url(opts)
      _                   -> item |> upload_file(opts)
    end
  end

  defp upload_url(url, opts) do
    params =
      opts
      |> Map.merge(%{file: url})
      |> Helpers.prepare_opts
      |> Helpers.sign
      |> URI.encode_query

    client(true)
    |> post("/image/upload", params)
    |> Helpers.handle_json_response
  end

  defp upload_file(file_path, opts) do
    file_path
    |> generate_upload_body(opts)
    |> file_upload
  end

  defp generate_upload_body(file_path, opts) do
    {
      :multipart,
      (
        opts
        |> Helpers.prepare_opts
        |> Helpers.sign
        |> Helpers.unify
        |> Map.to_list
      ) ++ [{:file, file_path}]
    }
  end

  defp file_upload(body) do
    url = "http://api.cloudinary.com/v1_1/#{Application.get_env(:cloudinex, :cloud_name)}/image/upload"
    headers =[
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Accept", "application/json"},
    ]
    {:ok, raw_response} = HTTPoison.request(
      :post,
      url,
      body,
      headers
    )
    {:ok, response} = Poison.decode(raw_response.body)
    IO.inspect response
  end

  defp client(form_url_encoded \\ false) do
    case form_url_encoded do
      true ->
        Tesla.build_client [{Tesla.Middleware.FormUrlencoded, %{}}]
      false ->
        Tesla.build_client [{Tesla.Middleware.JSON, %{}}]
    end
  end

  defp base_url do
    "#{Application.get_env(:cloudinex, :base_url)}#{Application.get_env(:cloudinex, :cloud_name)}"
  end
end
