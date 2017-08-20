defmodule Cloudinex.ValidationTest do
  @moduledoc false
  alias Cloudinex.Validation
  use ExUnit.Case

  describe "remove_invalid_keys/2" do
    test "remove_invalid_keys/2 removes invalid keys" do
      valid_keys = [:squirrel]
      list = [spicy: "chicken", squirrel: "rare"]
      expected = [squirrel: "rare"]
      assert expected == Validation.remove_invalid_keys(list, valid_keys)
    end

    test "remove_invalid_keys/2 removes all invalid keys" do
      valid_keys = [:squirrel]
      list = [spicy: "chicken"]
      expected = []
      assert expected == Validation.remove_invalid_keys(list, valid_keys)
    end
  end

  describe "valid_member?/3" do
    test "valid_member?/3 removes invalid list members" do
      list = [moderation_status: "squirrel"]
      key = :moderation_status
      enum = ["approved"]
      assert [] == Validation.valid_member?(list, enum, key)
    end

    test "valid_member?/3 maintains valid list members" do
      list = [moderation_status: "approved"]
      key = :moderation_status
      enum = ["approved"]
      assert list == Validation.valid_member?(list, enum, key)
    end
  end

  describe "valid_option?/3" do
    test "valid_option?/3 removes invalid list members" do
      list = [detection: "squirrel"]
      key = :detection
      value = "adv_face"
      assert [] == Validation.valid_option?(list, key, value)
    end

    test "valid_member?/3 maintains valid list members" do
      list = [detection: "adv_face"]
      key = :detection
      value = "adv_face"
      assert list == Validation.valid_option?(list, key, value)
    end
  end

  describe "valid_float_range?/4" do
    test "valid_float_range?/4 removes invalid list members" do
      list = [auto_tagging: 1.5]
      key = :auto_tagging
      low = 0.0
      high = 1.0
      assert [] == Validation.valid_float_range?(list, key, low, high)
    end

    test "valid_float_range?/4 maintains valid list members" do
      list = [auto_tagging: 0.5]
      key = :auto_tagging
      low = 0.0
      high = 1.0
      assert list == Validation.valid_float_range?(list, key, low, high)
    end
  end
end
