defmodule PastryTest do
  use ExUnit.Case
  doctest Pastry

  test "greets the world" do
    assert Pastry.hello() == :world
  end
end
