defmodule Cloudinex do
  @moduledoc false
  use Tesla, docs: false
  require Logger
  import Cloudinex.Helpers

  plug Tesla.Middleware.BaseUrl, base_url()
  plug Tesla.Middleware.BasicAuth, username: Application.get_env(:cloudinex, :api_key),
                                   password: Application.get_env(:cloudinex, :secret)
  plug Tesla.Middleware.FormUrlencoded
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
              |> Keyword.take(keys)

    options = case options[:tags] do
      nil ->
        options
      tags ->
        Keyword.put(options, :tags, join_list(tags))
    end

    options = case options[:context] do
      nil ->
        options
      context ->
        Keyword.put(options, :context, map_context(context))
    end    

    options = case options[:face_coordinates] do
      nil ->
        options
      face_coordinates ->
        Keyword.put(options, :face_coordinates, map_coordinates(face_coordinates))
    end   

    options = case options[:custom_coordinates] do
      nil ->
        options
      custom_coordinates ->
        Keyword.put(options, :custom_coordinates, map_coordinates(custom_coordinates))
    end  

    options = case Enum.member?(["approved", "rejected"], options[:moderation_status]) do
      true -> options
      false -> Keyword.delete(options, :moderation_status)
    end

    options = case is_float(options[:auto_tagging]) and options[:auto_tagging] >= 0.0 and options[:auto_tagging] <= 1.0 do
      true -> options
      false -> Keyword.delete(options, :auto_tagging)
    end

    options = case options[:detection] == "adv_face" do
      true -> options
      false -> Keyword.delete(options, :detection)
    end

    options = case options[:ocr] == "adv_ocr" do
      true -> options
      false -> Keyword.delete(options, :ocr)
    end    

    options = case options[:raw_convert] == "aspose" do
      true -> options
      false -> Keyword.delete(options, :raw_convert)
    end

    options = case options[:categorization] == "imagga_tagging" do
      true -> options
      false -> Keyword.delete(options, :categorization)
    end    

    options = case Enum.member?(["remove_the_background", "pixelz"], options[:background_removal]) do
      true -> options
      false -> Keyword.delete(options, :background_removal)
    end                
#  update_options = {
#       :moderation_status  => options[:moderation_status],
#       :auto_tagging       => options[:auto_tagging] && options[:auto_tagging].to_f,
# :detection          => options[:detection],
#       :ocr                => options[:ocr],

#       :raw_convert        => options[:raw_convert],
#       :categorization     => options[:categorization],
      
#       :similarity_search  => options[:similarity_search],
#       :background_removal => options[:background_removal],
      
#       :notification_url   => options[:notification_url]
#     }

    IO.inspect options
    # get(client(), url, query: options)
    # |> handle_response
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
