defmodule Cloudinex do
  @moduledoc false
  use Tesla, docs: false
  require Logger
  import Cloudinex.Helpers
  import Cloudinex.Validation

  plug Tesla.Middleware.BaseUrl, base_url()
  plug Tesla.Middleware.BasicAuth, username: Application.get_env(:cloudinex, :api_key),
                                   password: Application.get_env(:cloudinex, :secret)
  # plug Tesla.Middleware.FormUrlencoded
  plug Tesla.Middleware.JSON

  adapter Tesla.Adapter.Hackney

  def ping do
    get(client(), "/ping")
    |> handle_response
  end

  def usage do
    get(client(), "/usage")
    |> handle_response
  end

  def resource_types do
    get(client(), "/resources")
    |> handle_response
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

    get(client(), url, query: options)
    |> handle_response
  end

  def resources_by_tag(tag, options \\ []) do
    {resource_type, options} = Keyword.pop(options, :resource_type, "image")

    url = "/resources/#{resource_type}/tags/#{tag}"

    keys = [:max_results, :next_cursor, :direction, :tags, :context, :moderations]

    options = options
              |> Keyword.take(keys)

    get(client(), url, query: options)
    |> handle_response
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

    get(client(), url, query: options)
    |> handle_response
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

    get(client(), url, query: options)
    |> handle_response
  end

  def resource(public_id, options \\ []) do
    {resource_type, options} = Keyword.pop(options, :resource_type, "image")
    {type, options} = Keyword.pop(options, :type, "upload")

    url = "/resources/#{resource_type}/#{type}/#{public_id}"

    keys = [:colors, :exif, :faces, :image_metadata, :pages, :phash, 
            :coordinates, :max_results]

    options = options
              |> Keyword.take(keys)

    get(client(), url, query: options)
    |> handle_response
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
              |> parse_keyword(:face_coordinates, &Cloudinex.Helpers.map_coordinates/1)
              |> parse_keyword(:custom_coordinates, &Cloudinex.Helpers.map_coordinates/1)
              |> parse_keyword(:tags, &Cloudinex.Helpers.join_list/1)
              |> parse_keyword(:context, &Cloudinex.Helpers.map_context/1)
              |> valid_member?(["approved", "rejected"], :moderation_status)
              |> valid_member?(["remove_the_background", "pixelz"], :background_removal)
              |> valid_option?(:detection, "adv_face")
              |> valid_option?(:ocr, "adv_ocr")
              |> valid_option?(:raw_convert, "aspose")
              |> valid_option?(:categorization, "imagga_tagging")
              |> valid_float_range?(:auto_tagging, 0.0, 1.0)

    post(client(), url, unify(options))
    |> handle_response
  end

  def tags(options \\ []) do
    {resource_type, options} = Keyword.pop(options, :resource_type, "image")

    url = "/tags/#{resource_type}"

    keys = [:prefix, :max_results, :next_cursor]

    options = options
              |> Keyword.take(keys)

    get(client(), url, query: options)
    |> handle_response    
  end

  defp client() do
    case Application.get_env(:cloudinex, :debug) do
      true -> Tesla.build_client [{Tesla.Middleware.DebugLogger, %{}}]
      _ -> Tesla.build_client []
    end
  end

  defp base_url do
    "#{Application.get_env(:cloudinex, :base_url)}#{Application.get_env(:cloudinex, :cloud_name)}"
  end
end
