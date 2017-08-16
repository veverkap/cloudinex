defmodule Cloudinex do
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://api.cloudinary.com/v1_1/#{Application.get_env(:cloudinex, :cloud_name)}"
  plug Tesla.Middleware.BasicAuth, username: Application.get_env(:cloudinex, :api_key),
                                   password: Application.get_env(:cloudinex, :secret)
  plug Tesla.Middleware.FormUrlencoded
  # plug Tesla.Middleware.JSON

  adapter Tesla.Adapter.Hackney

 def resources(type) do
    get("/resources/#{type}")
  end

  # def upload(url) do
  #   opts \\ %{}opts \\ %{}
  #   # post("/image/upload", "file=data")
  #   # post("/image/upload")
  # end


  def upload_url(url, opts \\ %{}) do
    params = opts
          |> Map.merge(%{file: url})
          |> prepare_opts
          |> sign
          |> URI.encode_query
          |> IO.inspect

      post("/image/upload", params)
  end

  defp prepare_opts(%{tags: tags} = opts) when is_list(tags), do: %{opts | tags: Enum.join(tags, ",")}
  defp prepare_opts(opts), do: opts

  defp sign(data) do
    timestamp = current_time()

    data_without_secret = data
      |> Map.delete(:file)
      |> Map.merge(%{"timestamp" => timestamp})
      |> Enum.map(fn {key, val} -> "#{key}=#{val}" end)
      |> Enum.sort
      |> Enum.join("&")

    signature = (data_without_secret <> Application.get_env(:cloudinex, :secret))
      |> sha

    Map.merge(data, %{
      "timestamp" => timestamp,
      "signature" => signature,
      "api_key" => Application.get_env(:cloudinex, :api_key)
    })
  end

  defp sha(query) do
    :crypto.hash(:sha, query) |> Base.encode16 |> String.downcase
  end

  defp current_time do
    :os.system_time(:seconds)
      |> round
      |> Integer.to_string
  end

end
