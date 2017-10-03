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
    res = Gossip.Topologies.build_2D_grid(3)
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

end