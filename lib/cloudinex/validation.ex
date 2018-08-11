defmodule Cloudinex.Validation do
  @moduledoc false
  require Logger

  def validate_upload_options(_) do
    {:error, "Invalid options"}
  end

  def remove_invalid_keys(list, valid_keys) when is_list(list) do
    Keyword.take(list, valid_keys)
  end

  def valid_member?(list, enum, key) when is_list(list) do
    case Enum.member?(enum, list[key]) do
      true -> list
      false -> Keyword.delete(list, key)
    end
  end

  def valid_option?(list, key, value) when is_list(list) do
    case list[key] == value do
      true -> list
      false -> Keyword.delete(list, key)
    end
  end

  def valid_float_range?(list, key, low, high)
      when is_list(list) and is_float(low) and is_float(high) do
    case is_float(list[key]) and list[key] >= low and list[key] <= high do
      true -> list
      false -> Keyword.delete(list, key)
    end
  end

  def parse_keyword(list, key, fun) do
    case list[key] do
      nil -> list
      item -> Keyword.put(list, key, fun.(item))
    end
  end
end
