defmodule Cloudinex.Uploader do
  @moduledoc """
    Cloudinary is a cloud-based service that provides an end-to-end image management solution, including upload, storage, administration, manipulation, optimization and delivery.

    With Cloudinary you can easily upload images to the cloud and automatically perform smart image manipulations without installing any complex software. Cloudinary provides a secure and comprehensive API for easily uploading images from server-side code, directly from the browser or from a mobile application. You can either use Cloudinary's API directly or through one of Cloudinary's client libraries (SDKs), which wrap the upload API and simplify integration with web sites and mobile applications.

    The uploaded images can then be automatically converted to all relevant formats suitable for web viewing, optimized for web browsers and mobile devices, normalized, manipulated in real time, and delivered through a fast CDN to users (see the image transformations documentation for more information).

  """
  use Tesla, docs: false
  require Logger
  alias Cloudinex.{Helpers, Validation}
  alias Tesla.Multipart
  plug Tesla.Middleware.BaseUrl, base_url()
  plug Tesla.Middleware.BasicAuth, username: Helpers.api_key(),
                                   password: Helpers.secret()
  plug Cloudinex.Middleware, enabled: false
  plug Tesla.Middleware.FormUrlencoded
  adapter Tesla.Adapter.Hackney

  @doc """
    Creates a new image with the text binary provided

    ```elixir
    iex> Cloudinex.Uploader.upload_text("Your Text")
    {:ok,  %{
      "bytes" => 539,
      "created_at" => "2017-09-03T20:38:00Z",
      "format" => "png",
      "height" => 10,
      "public_id" => "FAKE",
      "resource_type" => "image",
      "secure_url" => "https://res.cloudinary.com/pdemo/image/text/image.png",
      "signature" => "ce43e5d06a3be722c926405f2a3905283e879357",
      "tags" => [],
      "type" => "text",
      "url" => "http://res.cloudinary.com/pdemo/image/text/image.png",
      "version" => 1504471080,
      "width" => 33}}}
    ```
  """
  @spec upload_text(text :: String.t, options :: Map.t) :: {atom, Map.t}
  def upload_text(text, opts \\ %{}) do
    params =
      opts
      |> Map.merge(%{text: text})
      |> Helpers.prepare_opts
      |> Helpers.sign
      |> URI.encode_query

    client()
    |> post("/image/text", params)
    |> Helpers.handle_json_response
  end

  @doc """
    Uploads provided URL of an image on the internet

    ```elixir
    iex> Cloudinex.Uploader.upload_url("http://example.com/example.jpg")
    {:ok,
      %{"bytes" => 228821,
        "created_at" => "2017-09-03T20:43:45Z",
        "etag" => "96703c568b938567551bf0e408ab2f2a",
        "format" => "jpg",
        "height" => 2048,
        "original_filename" => "02qqN5T",
        "public_id" => "i5duxjofpqcdprjl0gag",
        "resource_type" => "image",
        "secure_url" => "https://res.cloudinary.com/demo/image/upload/v1504471425/i5duxjofpqcdprjl0gag.jpg",
        "signature" => "5f0475dfb785049d97f937071802ee88cc153ed0",
        "tags" => [],
        "type" => "upload",
        "url" => "http://res.cloudinary.com/demo/image/upload/v1504471425/i5duxjofpqcdprjl0gag.jpg",
        "version" => 1504471425,
        "width" => 2048}}
    ```

    [API Docs](http://cloudinary.com/documentation/upload_images#uploading_with_a_direct_call_to_the_api)
  """
  @spec upload_url(url :: String.t, options :: Map.t) :: {atom, Map.t}
  def upload_url(url, options \\ %{}) do
    # with {:ok, options} <- Validation.validate_upload_options(options) do
      params =
        options
        |> Map.merge(%{file: url})
        |> Helpers.prepare_opts
        |> Helpers.sign
        |> URI.encode_query

      client()
      |> post("/image/upload", params)
      |> Helpers.handle_json_response
    # end
  end

  @doc """
    Uploads file

    ```elixir
    iex> Cloudinex.Uploader.upload_url("./example.jpg")
    {:ok,
      %{"bytes" => 228821,
        "created_at" => "2017-09-03T20:43:45Z",
        "etag" => "96703c568b938567551bf0e408ab2f2a",
        "format" => "jpg",
        "height" => 2048,
        "original_filename" => "02qqN5T",
        "public_id" => "i5duxjofpqcdprjl0gag",
        "resource_type" => "image",
        "secure_url" => "https://res.cloudinary.com/demo/image/upload/v1504471425/i5duxjofpqcdprjl0gag.jpg",
        "signature" => "5f0475dfb785049d97f937071802ee88cc153ed0",
        "tags" => [],
        "type" => "upload",
        "url" => "http://res.cloudinary.com/demo/image/upload/v1504471425/i5duxjofpqcdprjl0gag.jpg",
        "version" => 1504471425,
        "width" => 2048}}
    ```

    [API Docs](http://cloudinary.com/documentation/upload_images#uploading_with_a_direct_call_to_the_api)
  """
  @spec upload_file(file_path :: String.t, options :: Map.t) :: {atom, Map.t}
  def upload_file(file_path, options \\ %{}) do
    options
    |> generate_upload_keys
    |> file_upload(file_path)
  end

  defp file_upload(%{"api_key" => api_key, "signature" => signature, "timestamp" => timestamp}, file_path) do

    mp = Multipart.new
         |> Multipart.add_content_type_param("application/x-www-form-urlencoded")
         |> Multipart.add_field("api_key", api_key)
         |> Multipart.add_field("signature", signature)
         |> Multipart.add_field("timestamp", timestamp)
         |> Multipart.add_file(file_path)

    client()
    |> post("/image/upload", mp)
    |> Helpers.handle_json_response
  end

  defp generate_upload_keys(options) do
    options
    |> Helpers.prepare_opts
    |> Helpers.sign
    |> Helpers.unify
  end

  defp client do
    Tesla.build_client []
  end

  defp base_url do
    Helpers.base_url() <> Helpers.cloud_name
  end
end
