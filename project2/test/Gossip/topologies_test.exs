defmodule TopologiesTest do
  use ExUnit.Case
  doctest Gossip.Topologies

  @doc """
  Given numNodes, bring up a 2D (square) grid
  of Actors. Each actor should only be able to talk 
  to its neighbors.
  """
  # test "create a 2D grid network" do
  #   numNodes = 9
  #   # Returns a list of nodes, to be started by a superviser
  #   nodes = Topologies.build2DGrid(numNodes)
  #   assert length(nodes) == 9
  # end

  test "create 2D array" do
    res = Gossip.Topologies.multi_list(5)
    assert res |> Enum.at(2) |> Enum.at(2) == 12
  end

  test "Assign neighbors to 3 x 3 grid" do 
    res = Gossip.Topologies.build_2D_grid(3)
    # Check bottom right corner
    assert List.first(res)[8] == [5, 7]
  end


end