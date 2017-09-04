defmodule Graph.Search do
@moduledoc """
  Returns a path in the given graph from start node to end node.
  """
  use GenServer

  @doc """
  initialize BFS server
  """
  def init(:ok) do
      {:ok, %{}}
  end

  @doc """
  Return the DFS path from start_v to end_v
  """
  def handle_call({:dfs, {my_graph, start_v, end_v}}, _from, %{}) do
      {:reply, :ok, :digraph.get_path(my_graph, start_v, end_v)}
  end
end
