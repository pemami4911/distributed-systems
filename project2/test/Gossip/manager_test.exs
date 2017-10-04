defmodule ManagerTest do
  use ExUnit.Case
  doctest Gossip.Manager

  test "build_actor_args" do
    neighbors = [%{1 => [0, 2]}, %{2 => [3]}]
    actor_args = Gossip.Manager.build_actor_args(neighbors, 20)
      |> List.first
    assert actor_args[:name] == 1
    assert actor_args[:neighbors] == [0,2]
  end 

  test "build_child_specs" do
    actor_args = [%{:name => 1, :neighbors => [0, 2], :gossip_limit => 10}]
    Gossip.Manager.build_children([], actor_args)
  end

end