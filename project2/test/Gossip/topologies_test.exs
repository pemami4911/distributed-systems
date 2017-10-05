defmodule TopologiesTest do
  use ExUnit.Case
  doctest Gossip.Topologies

  test "create 2D array" do
    res = Gossip.Topologies.multi_list(5)
    assert res |> Enum.at(2) |> Enum.at(2) == 12
  end

  @doc """
  Given numNodes, bring up a 2D (square) grid
  of Actors. Each actor should only be able to talk 
  to its neighbors.
  """
  test "Assign neighbors to 3 x 3 grid" do 
    res = Gossip.Topologies.build_2D(3)
    # Check bottom right corner
    assert List.first(res)[8] == [5, 7]
  end

  @doc """
  Given num_nodes, bring up a 1D (line) 
  of Actors. Each actor should have two neighbors
  except for left corner and right corner
  """
  test "Assign neighbors to line of 5 actors" do
    res = Gossip.Topologies.build_1D(5)
  
    assert List.first(res)[4] == [3]
    {_, res} = List.pop_at(res, 0)
    assert List.first(res)[3] == [2, 4]
  end

  @doc """
  Given num_nodes, bring up a fully connected
  graph of actors. Each actor should have the 
  others as its neighbors
  """
  test "Assign neighbors to fully connected network" do
    res = Gossip.Topologies.build_full(5)
    assert List.first(res)[0] == [1, 2, 3, 4]
  end

  test "Assign neighbors to imp 2D" do
    res = Gossip.Topologies.build_imp2D(3) 
    assert length(List.first(res)[8]) == 3
  end

end