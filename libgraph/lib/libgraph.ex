defmodule Graph do
  @moduledoc """
  A libgraph client for carrying out 
  operations on graphs.
  """
  use GenServer

  @doc """
  Starts the graph server
  """
  def start_link(opts) do
    GenServer.start_link(Graph.Search, :ok, opts)
  end

  @doc """
  Create an empty Erlang digraph.
  """
  def init() do
    :digraph.new()
  end

  @doc """
  Pass a graph to the search server specified
  to get the DFS path from start to end.
  """
  def dfs(search_server, my_graph, start_v, end_v) do
    GenServer.call(search_server, {:dfs, {my_graph, start_v, end_v}})
  end

end
