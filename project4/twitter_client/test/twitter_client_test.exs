defmodule Twitter.ClientTest do
  use ExUnit.Case
  doctest Twitter.Client

  test "greets the world" do
    assert Twitter.Client.hello() == :world
  end
end
