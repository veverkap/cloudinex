defmodule Cloudinex do
  @moduledoc false
  use Tesla
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

    get(client(), url, query: options)
    |> handle_response
  end

  def resources_by_tag(tag, options \\ []) do
    {resource_type, options} = Keyword.pop(options, :resource_type, "image")

    url = "/resources/#{resource_type}/tags/#{tag}"
    Logger.info url

    get(client(), url, query: options)
    |> handle_response
  end

  def resources_by_context(context, value \\ nil, options \\ []) do
    {resource_type, options} = Keyword.pop(options, :resource_type, "image")

    url = case value do
      nil ->
        "/resources/#{resource_type}/context/?key=#{context}"
      value ->
        "/resources/#{resource_type}/context/?key=#{context}&value=#{value}"
    end

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
