defmodule Gossip.Topologies do
  @moduledoc """
  Documentation for the Topologies module. This module 
  contains various algorithms for building 

  1. fully connected network
  2. 2-D grids
  3. line
  4. grid++

  Each method takes the number of nodes in the topology and the args
  for passing to each node as input. 

  Returns a list of all nodes in the topology.
  """

  @doc """
  Creates a 2D array representing each node. Iterate L->R,
  top to bottom over the array, assigning neighbors using 
  adjacent array entries.

  num_nodes is the row/col length
  """
  def build_2D_grid(num_nodes) do
    l = multi_list(num_nodes)
    iterate_grid(0, 0, l, num_nodes, [])
  end

  ##############################
  # HELPERS FOR 2D GRID
  ##############################
  def multi_list(n) do
    {rr, k} = row(n - 1, [0], 1)
    add_row(n - 1, n, [rr], k)
  end

  defp add_row(iter, n, matrix, k) when iter > 0 do
    {rr, k} = row(n - 1, [k], k + 1)
    matrix = matrix ++ [rr]
    add_row(iter - 1, n, matrix, k)
  end

  defp add_row(_iter, _n, matrix, _k) do
    matrix
  end

  defp row(iter, r, k) when iter > 0 do
     r = r ++ [k]
     row(iter - 1, r, k + 1)
  end

  defp row(_iter, r, k) do
    {r, k}
  end

  @doc """
  |----|----|
  |__(i,j)__|
  |----|----|

  i,j are the indices of the nodes. m is the multi-dim list
  containing the nodes IDs. n is the row/col length of m. 

  returns a list of the neighbors of node (i,j)
  """
  def neighbors(i, j, m, n)  do
    cond do
      is_internal(i, j, n) ->
        n1 = m 
          |> Enum.at(i-1) 
          |> Enum.at(j)
        n2 = m
          |> Enum.at(i+1)
          |> Enum.at(j)
        n3 = m 
          |> Enum.at(i)
          |> Enum.at(j-1)
        n4 = m
          |> Enum.at(i)
          |> Enum.at(j+1)
        [n1, n2, n3, n4]
      # check top edge
      i == 0 ->
        cond do
          # check top left corner
          j == 0 ->
            n1 = m
              |> Enum.at(i)
              |> Enum.at(j+1)
            n2 = m
              |> Enum.at(i+1)
              |> Enum.at(j)
            [n1, n2]
          # check top right corner
          j == n - 1 ->
            n1 = m
              |> Enum.at(i+1)
              |> Enum.at(j)
            n2 = m
              |> Enum.at(i)
              |> Enum.at(j-1)
            [n1, n2]
          # center of top edge
          true ->
            n1 = m
              |> Enum.at(i)
              |> Enum.at(j-1)
            n2 = m
              |> Enum.at(i)
              |> Enum.at(j+1)
            n3 = m
              |> Enum.at(i+1)
              |> Enum.at(j)
            [n1, n2, n3]
        end
      # check bottom edge
      i == n - 1 ->
        cond do
          # check bottom left corner
          j == 0 ->
            n1 = m
              |> Enum.at(i-1)
              |> Enum.at(j)
            n2 = m
              |> Enum.at(i)
              |> Enum.at(j+1)
            [n1, n2]
          # check bottom right corner
          j == n - 1 ->
            n1 = m
              |> Enum.at(i-1)
              |> Enum.at(j)
            n2 = m
              |> Enum.at(i)
              |> Enum.at(j-1)
            [n1, n2]
          # check center of bottom edge
          true ->
            n1 = m
              |> Enum.at(i)
              |> Enum.at(j-1)
            n2 = m
              |> Enum.at(i)
              |> Enum.at(j+1)
            n3 = m
              |> Enum.at(i-1)
              |> Enum.at(j)
            [n1, n2, n3]
        end
      # check left edge
      j == 0 ->
        n1 = m
          |> Enum.at(i-1)
          |> Enum.at(j)
        n2 = m
          |> Enum.at(i+1)
          |> Enum.at(j)
        n3 = m
          |> Enum.at(i)
          |> Enum.at(j+1)
        [n1, n2, n3]
      # check right edge
      j == n - 1 ->
        n1 = m
          |> Enum.at(i-1)
          |> Enum.at(j)
        n2 = m
          |> Enum.at(i+1)
          |> Enum.at(j)
        n3 = m
          |> Enum.at(i)
          |> Enum.at(j-1)
        [n1, n2, n3]      
      end
  end

  defp is_internal(i, j, n) do
    if i > 0 && j > 0 && i < n-1 && j < n-1 do
      true
    else
      false
    end
  end

  def iterate_grid(i, j, m, n, node_list) do
    {i, j, nbs, k} = 
      if j == n do
        {i + 1, 0, nil, 0}
      else
        nbs = neighbors(i, j, m, n)
        k = m |> Enum.at(i) |> Enum.at(j)         
        {i, j + 1, nbs, k}
      end
    cond do 
      nbs -> # new col
        if i < n do
          node_list ++ iterate_grid(i, j, m, n, node_list) ++ [%{k => nbs}]
        else
          node_list
        end
      i < n -> # new row
        node_list ++ iterate_grid(i, j, m, n, node_list)
      true -> # done
        node_list
    end
  end

  # def buildFullyConnected(num_nodes) do
  # end

  # def buildLine(num_nodes) do
  # end

  # def buildImperfect2DGrid(num_nodes) do
  # end

end
