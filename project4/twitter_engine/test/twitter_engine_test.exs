defmodule Twitter.EngineTest do
  use ExUnit.Case
  doctest Twitter.Engine

  test "greets the world" do
    assert Twitter.Engine.hello() == :world
  end
end
