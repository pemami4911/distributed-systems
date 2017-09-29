defmodule TopologiesTest do
  use ExUnit.Case
  doctest Topologies

  @doc """
  Given numNodes, bring up a 2D (square) grid
  of Actors. Each actor should only be able to talk 
  to its neighbors.
  """
  test "create a 2D grid network" do
    numNodes = 9
    # Returns a list of nodes, to be started by a superviser
    nodes = Topologies.build2DGrid(numNodes)
    assert length(nodes) == 9
  end


end