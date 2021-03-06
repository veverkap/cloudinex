defmodule Cloudinex.Helpers do
  @moduledoc """
    These are helper functions that assist with handling responses and creating
    requests
  """

  @doc """
    Converts Enumerable of tuples to key value map

    ```ex
    %{"first" => "value"} = Cloudinex.Helpers.unify([first: "value"])
    ```
  """
  @spec unify(data :: Enum.t()) :: Map.t()
  def unify(nil), do: nil

  def unify(data) do
    data
    |> Enum.reduce(%{}, fn {k, v}, acc ->
      Map.put(acc, "#{k}", v)
    end)
  end

  @doc """
    Joins enumerable
  """
  @spec join_list(list :: Enum.t()) :: String.t()
  def join_list(nil), do: ""
  def join_list(list), do: Enum.join(list, ",")

  @doc """
    Maps context
  """
  @spec map_context(context :: Map.t()) :: String.t()
  def map_context(nil), do: nil

  def map_context(context) when is_map(context) do
    context
    |> Map.to_list()
    |> Enum.map_join("|", fn {a, b} -> "#{a}=#{b}" end)
  end

  @doc """
    Maps coordinates
  """
  @spec map_coordinates(coordinates :: List.t()) :: String.t()
  def map_coordinates(nil), do: nil

  def map_coordinates(coordinates) when is_list(coordinates) do
    coordinates
    |> Enum.map_join("|", fn {a, b, c, d} -> "#{a},#{b},#{c},#{d}" end)
  end

  @doc """
    Prepares options for POST upload
  """
  @spec prepare_opts(options :: Map.t()) :: Map.t()
  def prepare_opts(%{tags: tags} = options) when is_list(tags),
    do: %{options | tags: Enum.join(tags, ",")}

  def prepare_opts(options), do: options

  @doc """
    Handles the response from the form url encoded upload
  """
  @spec handle_json_response(env :: Map.t()) :: {atom, String.t()}
  def handle_json_response({:ok, env}), do: handle_json_response(env)

  def handle_json_response(env) do
    case handle_response(env) do
      {:ok, body} -> Jason.decode(body)
      anything -> anything
    end
  end

  @doc """
    Handles any method with !
  """
  @spec handle_bang_response(env :: Map.t()) :: String.t() | RuntimeError
  def handle_bang_response({:ok, env}), do: handle_bang_response(env)

  def handle_bang_response(env) do
    case handle_response(env) do
      {:error, message} -> raise RuntimeError, message: message
      {:ok, result} -> result
    end
  end

  @doc """
    Handles any normal response
  """
  @spec handle_response(env :: Map.t()) :: {atom, String.t()}
  def handle_response({:ok, env}), do: handle_response(env)

  def handle_response(%{status: 200, body: body}), do: {:ok, body}

  def handle_response(%{status: 400, body: body}) when is_binary(body),
    do: handle_response({:ok, %{status: 400, body: Jason.decode!(body)}})

  def handle_response(%{status: 400, body: body}) when is_map(body) do
    message = Kernel.get_in(body, ["error", "message"])
    {:error, "Bad Request: #{message}"}
  end

  def handle_response(%{status: 401}),
    do: {:error, "Invalid Credentials: Please check your api_key and secret"}

  def handle_response(%{status: 403}),
    do: {:error, "Invalid Credentials: Please check your api_key and secret"}

  def handle_response(%{status: 404}),
    do: {:error, "Resource not found"}

  # This should really be a 429, but they are using 420
  def handle_response(%{status: 420, headers: headers} = env) when not is_nil(headers) do
    case Tesla.get_header(env, "x-featureratelimit-reset") do
      nil ->
        {:error, "Your rate limit will be reset on unknown date"}

      reset_date ->
        {:error, "Your rate limit will be reset on #{reset_date}"}
    end
  end

  def handle_response(%{status: 500, body: body}) do
    {:error, "General Error: #{body}"}
  end

  def handle_response(%{body: body}), do: {:error, body}

  def handle_response(response),
    do: {:error, "Unhandled response from Cloudinary #{inspect(response)}"}

  @doc """
    Atomizes an enumerable
  """
  @spec atomize(item :: List.t() | Map.t()) :: Map.t()
  def atomize(item) when is_list(item) or is_map(item) do
    Enum.map(item, fn {k, v} -> {String.to_atom(k), v} end)
  end

  @doc """
    Takes parameters and creates signature per [Cloudinary docs](http://cloudinary.com/documentation/upload_images#creating_api_authentication_signatures)
  """
  @spec sign(data :: Map.t()) :: Map.t()
  def sign(data) do
    timestamp = current_time()

    data_without_secret =
      data
      |> Map.delete(:file)
      |> Map.merge(%{"timestamp" => timestamp})
      |> Enum.map(fn {key, val} -> "#{key}=#{val}" end)
      |> Enum.sort()
      |> Enum.join("&")

    signature =
      (data_without_secret <> Application.get_env(:cloudinex, :secret))
      |> sha

    Map.merge(data, %{
      "timestamp" => timestamp,
      "signature" => signature,
      "api_key" => Application.get_env(:cloudinex, :api_key)
    })
  end

  @spec crypto_hash(query :: String.t()) :: String.t()
  def crypto_hash(query), do: :crypto.hash(:sha, query)

  @spec api_key :: String.t()
  def api_key, do: Application.get_env(:cloudinex, :api_key)

  @spec base_image_url :: String.t()
  def base_image_url do
    Application.get_env(
      :cloudinex,
      :base_image_url,
      "https://res.cloudinary.com/"
    )
  end

  @spec base_url :: String.t()
  def base_url do
    Application.get_env(
      :cloudinex,
      :base_url,
      "https://api.cloudinary.com/v1_1/"
    )
  end

  @spec cloud_name :: String.t()
  def cloud_name, do: Application.get_env(:cloudinex, :cloud_name)

  @spec debug? :: String.t()
  def debug?, do: Application.get_env(:cloudinex, :debug, false)

  @spec secret :: String.t()
  def secret, do: Application.get_env(:cloudinex, :secret)

  defp sha(query) do
    query
    |> crypto_hash
    |> Base.encode16()
    |> String.downcase()
  end

  defp current_time do
    system_time()
    |> round
    |> Integer.to_string()
  end

  defp system_time, do: :os.system_time(:seconds)
end
