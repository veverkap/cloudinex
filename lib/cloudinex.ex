defmodule Cloudinex do
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://api.cloudinary.com/v1_1/#{Application.get_env(:cloudinex, :cloud_name)}"
  plug Tesla.Middleware.BasicAuth, username: Application.get_env(:cloudinex, :api_key),
                                   password: Application.get_env(:cloudinex, :secret)
  plug Tesla.Middleware.FormUrlencoded
  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.DebugLogger
  adapter Tesla.Adapter.Hackney

  def ping do
    get("/ping")
    |> handle_response
  end

  def usage do
    get("/usage")
    |> handle_response
  end

  def resource_types do
    get("/resources")
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

    get(url, query: options)
    |> handle_response
  end

  def resources_by_tag(tag, options \\ []) do
    {resource_type, options} = Keyword.pop(options, :resource_type, "image")

    url = "/resources/#{resource_type}/tags/#{tag}"

    get(url, query: options)
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

    get(url, query: options)
    |> handle_response
  end

  
  defp handle_response(%{status: 200, body: body, headers: headers}) do
    IO.inspect headers
    {:ok, body}
  end

  defp handle_response(%{status: status, body: body}) do
    {:error, body}
  end

end
