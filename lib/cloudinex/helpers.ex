defmodule Cloudinex.Helpers do
  @moduledoc false
  #  Unifies hybrid map into string-only key map.
  #  ie. `%{a: 1, "b" => 2} => %{"a" => 1, "b" => 2}`
  def unify(data) do
    data
    |> Enum.reduce(%{}, fn {k, v}, acc ->
      Map.put(acc, "#{k}", v)
    end)
  end

  def prepare_opts(%{tags: tags} = opts) when is_list(tags), do: %{opts | tags: Enum.join(tags, ",")}
  def prepare_opts(opts), do: opts

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
end
