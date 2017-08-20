defmodule Cloudinex.HelpersTest do
  @moduledoc false
  use ExUnit.Case

  describe "unify/1" do
    test "unify/1 handles nil" do
      assert nil == Cloudinex.Helpers.unify(nil)
    end

    test "unify/1 handles enumerable" do
      assert %{"a" => 1} == Cloudinex.Helpers.unify(%{a: 1})
    end
  end

  describe "join_list/1" do
    test "join_list/1 handles nil" do
      assert "" == Cloudinex.Helpers.join_list(nil)
    end

    test "join_list/1 joins strings" do
      assert "a,b" == Cloudinex.Helpers.join_list(["a", "b"])
    end

    test "join_list/1 joins numbers" do
      assert "1,2" == Cloudinex.Helpers.join_list([1, 2])
    end
  end

  describe "map_context/1" do
    test "map_context/1 handles nil" do
      assert nil == Cloudinex.Helpers.map_context(nil)
    end

    test "map_context/1 joins" do
      assert "a=b" == Cloudinex.Helpers.map_context(%{a: "b"})
    end
  end
end
