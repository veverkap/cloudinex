defmodule Cloudinex.Helpers do
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
end
