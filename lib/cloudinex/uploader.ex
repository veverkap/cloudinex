defmodule Cloudinex.Uploader do
  @moduledoc false
  use Tesla, docs: false
  require Logger
  alias Cloudinex.Helpers

  plug Tesla.Middleware.BaseUrl, base_url()
  plug Tesla.Middleware.BasicAuth, username: Application.get_env(:cloudinex, :api_key),
                                   password: Application.get_env(:cloudinex, :secret)
  plug Cloudinex.Middleware, enabled: false
  plug Tesla.Middleware.FormUrlencoded
  adapter Tesla.Adapter.Hackney

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

    client()
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
    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Accept", "application/json"},
      {"user-agent", "cloudinex/#{Cloudinex.version}"}
    ]
    {:ok, raw_response} = HTTPoison.request(
      :post,
      "#{base_url()}/image/upload",
      body,
      headers
    )
    {:ok, response} = Poison.decode(raw_response.body)
    response
  end

  defp client do
    Tesla.build_client []
  end

  defp base_url do
    "#{Application.get_env(:cloudinex, :base_url)}#{Application.get_env(:cloudinex, :cloud_name)}"
  end
end
