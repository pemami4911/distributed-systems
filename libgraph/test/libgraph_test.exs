defmodule GraphTest do
  use ExUnit.Case, async: true

  doctest Graph

  setup do 
    {:ok, search_server} = Graph.start_link([])
    mygraph = Graph.init()    
    %{testgraph: mygraph, search_server: search_server}
  end

  test "create empty graph ", %{testgraph: mygraph} do
    assert mygraph.no_edges() == 0
    assert mygraph.no_vertices() == 0
  end

  test "add verts and edges to my graph", %{testgraph: mygraph} do
    v1 = :digraph.add_vertex(mygraph, {0.0, 0.0})
    v2 = :digraph.add_vertex(mygraph, {1.0, 1.0})
    :digraph.add_edge(mygraph, v1, v2)
    assert mygraph.no_edges() == 1
    assert mygraph.no_vertices() == 2
  end

  test "find BFS path", %{testgraph: mygraph, search_server: search_server} do
    v1 = :digraph.add_vertex(mygraph, {0.0, 0.0})
    v2 = :digraph.add_vertex(mygraph, {1.0, 1.0})
    v3 = :digraph.add_vertex(mygraph, {4.0, -1.0})
    :digraph.add_edge(mygraph, v1, v2)
    :digraph.add_edge(mygraph, v2, v3)
    Graph.dfs(search_server, mygraph, v1, v3)
  end


end
