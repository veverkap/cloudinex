# defmodule Cloudinex do
#   use Tesla

#   plug Tesla.Middleware.BaseUrl, "https://api.cloudinary.com/v1_1/#{Application.get_env(:cloudinex, :cloud_name)}"
#   plug Tesla.Middleware.BasicAuth, username: Application.get_env(:cloudinex, :api_key),
#                                    password: Application.get_env(:cloudinex, :secret)
#   plug Tesla.Middleware.FormUrlencoded
#   # plug Tesla.Middleware.JSON

#   adapter Tesla.Adapter.Hackney

#  def resources(type) do
#     get("/resources/#{type}")
#   end

#   # def upload(url) do
#   #   opts \\ %{}opts \\ %{}
#   #   # post("/image/upload", "file=data")
#   #   # post("/image/upload")
#   # end
#   def upload_file(file_path, opts) do
#     body = {:multipart, (opts |> prepare_opts |> sign |> unify |> Map.to_list) ++ [{:file, file_path}]}
#     IO.inspect body
#     # body |> post(file_path)
#   end

#   def upload_url(url, opts \\ %{}) do
#     params = opts
#           |> Map.merge(%{file: url})
#           |> prepare_opts
#           |> sign
#           |> URI.encode_query
#           |> IO.inspect

#       post("/image/upload", params)
#   end

#   defp prepare_opts(%{tags: tags} = opts) when is_list(tags), do: %{opts | tags: Enum.join(tags, ",")}
#   defp prepare_opts(opts), do: opts


#   def ppost(body, source) do
#     with {:ok, raw_response} <- HTTPoison.request(
#       :post,
#       "http://api.cloudinary.com/v1_1/#{Application.get_env(:cloudinex, :cloud_name)}/image/upload",
#       body,
#       [
#         {"Content-Type", "application/x-www-form-urlencoded"},
#         {"Accept", "application/json"},
#       ]
#     ),
#     {:ok, response} <- Poison.decode(raw_response.body),
#     do: handle_response(response, source)
#   end

#   defp handle_response(response, source) do
#     IO.inspect response
#     IO.inspect source
#   end

#   defp sign(data) do
#     timestamp = current_time()

#     data_without_secret = data
#       |> Map.delete(:file)
#       |> Map.merge(%{"timestamp" => timestamp})
#       |> Enum.map(fn {key, val} -> "#{key}=#{val}" end)
#       |> Enum.sort
#       |> Enum.join("&")

#     signature = (data_without_secret <> Application.get_env(:cloudinex, :secret))
#       |> sha

#     Map.merge(data, %{
#       "timestamp" => timestamp,
#       "signature" => signature,
#       "api_key" => Application.get_env(:cloudinex, :api_key)
#     })
#   end

#   defp sha(query) do
#     :crypto.hash(:sha, query) |> Base.encode16 |> String.downcase
#   end

#   defp current_time do
#     :os.system_time(:seconds)
#       |> round
#       |> Integer.to_string
#   end

#   #  Unifies hybrid map into string-only key map.
#   #  ie. `%{a: 1, "b" => 2} => %{"a" => 1, "b" => 2}`
#   defp unify(data) do
#     data
#       |> Enum.reduce(%{}, fn {k, v}, acc ->
#         Map.put(acc, "#{k}", v)
#       end)
#   end

# end
