defmodule Gossip.Manager do
  @moduledoc """
  Supervisor that manages all processes
  in Gossip
  """
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def init(opts) do
    # each actor should receive gossip_limit msgs
    # before stopping spreading rumors
    gossip_limit = 10

    # 1. Build the topology, which involves assigning
    # nodes their neighbors
    
    neighbors =  
      cond do
        opts[:topology] == "2D" ->
          # Given numNodes - compute the square len/width
          # by finding the nearest perfect square
          :math.sqrt(opts[:numNodes]) 
            |> Float.ceil
            |> Gossip.Topologies.build_2D_grid

        opts[:topology] == "line" ->
          Gossip.Topologies.build_1D(opts[:numNodes])

        opts[:topology] == "full" ->
          IO.puts "not implemented"
        opts[:topology] == "imp2D" ->
          IO.puts "not implemented"
        true ->
          IO.puts(:stderr, "unsupported topology provided: #{opts[:topology]}")
          System.halt(1)
      end
    
    
    actor_args = build_actor_args(neighbors, gossip_limit)
    # gossip algo args
    gossip_args = [topLevel: opts[:topLevel], numNodes: length(neighbors)]
    build_children([], actor_args) ++ 
      [Supervisor.child_spec({Gossip.GossipAlgo, gossip_args}, id: -1)]
      |> Supervisor.init(strategy: :one_for_one)
  end

  def build_actor_args(neighbors, gl) do
    Enum.map(neighbors, fn x -> 
      k = List.first(Map.keys(x))
      [%{:name => k, :neighbors => x[k], :gossip_limit => gl}] end
    ) |> Enum.concat
  end

  def build_children(children, [args | list]) when length(list) > 0 do
    children ++ [Supervisor.child_spec({Gossip.Actor, args}, id: args[:name])]
      |> build_children(list)
  end

  def build_children(children, [args]) do
    children ++ [Supervisor.child_spec({Gossip.Actor, args}, id: args[:name])]
  end

end