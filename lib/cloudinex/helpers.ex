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
  def join_list(nil), do: ""
  def join_list(list), do: Enum.join(list, ",")

  @doc """
  Maps context
  """
  def map_context(nil), do: nil
  def map_context(context) when is_map(context) do
    context
    |> Map.to_list
    |> Enum.map_join("|", fn({a, b}) -> "#{a}=#{b}" end)
  end

  def map_coordinates(nil), do: nil
  def map_coordinates(coordinates) when is_list(coordinates) do
    coordinates
    |> Enum.map_join("|", fn({a, b, c, d}) -> "#{a},#{b},#{c},#{d}" end)
  end

  def prepare_opts(%{tags: tags} = opts) when is_list(tags), do: %{opts | tags: Enum.join(tags, ",")}
  def prepare_opts(opts), do: opts

  def handle_json_response(env) do
    case handle_response(env) do
      {:ok, body} -> Poison.decode(body)
      anything -> anything
    end
  end
  def handle_response(%{status: 200, body: body}), do: {:ok, body}
  def handle_response(%{status: 400, body: body}) do
    message = Kernel.get_in(body, ["error", "message"])
    {:error, "Bad Request: #{message}"}
  end
  def handle_response(%{status: 401}), do: {:error, "Invalid Credentials: Please check your api_key and secret"}
  def handle_response(%{status: 403}), do: {:error, "Invalid Credentials: Please check your api_key and secret"}
  def handle_response(%{status: 404}), do: {:error, "Resource not found"}

  # This should really be a 429, but they are using 420
  def handle_response(%{status: 420, headers: headers}) do
    reset_date = Map.get(headers, "x-featureratelimit-reset", "unknown date")
    {:error, "Your rate limit will be reset on #{reset_date}"}
  end

  def handle_response(%{status: 500, body: body}) do
    {:error, "General Error: #{body}"}
  end

  def handle_response(%{body: body}), do: {:error, body}

  def sign(data) do
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

  def sha(query) do
    query
    |> hash
    |> Base.encode16
    |> String.downcase
  end

  def hash(query), do: :crypto.hash(:sha, query)

  def current_time do
    system_time()
    |> round
    |> Integer.to_string
  end

  def system_time, do: :os.system_time(:seconds)
end
