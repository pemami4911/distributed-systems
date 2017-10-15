defmodule Gossip.Manager do
  @moduledoc """
  Supervisor that manages all processes
  in Gossip
  """
  require Logger
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def init(opts) do
    # 1. Build the topology, which involves assigning
    # nodes their neighbors
    
    neighbors =  
      cond do
        opts[:topology] == "2D" ->
          # Given numNodes - compute the square len/width
          # by finding the nearest perfect square
          :math.sqrt(opts[:numNodes]) 
            |> Float.ceil
            |> round
            |> Gossip.Topologies.build_2D

        opts[:topology] == "line" ->
          Gossip.Topologies.build_1D(opts[:numNodes])

        opts[:topology] == "full" ->
          Gossip.Topologies.build_full(opts[:numNodes])

        opts[:topology] == "imp2D" ->
          :math.sqrt(opts[:numNodes]) 
          |> Float.ceil
          |> round
          |> Gossip.Topologies.build_imp2D
        true ->
          Logger.error "unsupported topology provided: #{opts[:topology]}"
          System.halt(1)
      end
    
    {actor_args, actor} = 
      cond do 
        opts[:algorithm] == "gossip" ->
          build_actor_args(neighbors, "gossip", 15)
        opts[:algorithm] == "push-sum" ->
          build_actor_args(neighbors, "push-sum", :math.pow(10, -10))
        true ->
          Logger.error "unsupported algorithm provided: #{opts[:algorithm]}"
          System.halt(1)
      end
        # gossip algo args
    gossip_args = [topLevel: opts[:topLevel], numNodes: length(neighbors)]

    Enum.reduce(actor_args, [], fn(x, acc) ->
      [Supervisor.child_spec({actor, x}, id: x[:name]) | acc] end) ++ 
      [Supervisor.child_spec({Gossip.GossipAlgo, gossip_args}, id: -1)]
      |> Supervisor.init(strategy: :one_for_one)
  end

  defp build_actor_args(neighbors, algo, info) do
    cond do
      algo == "gossip" ->
        nbs =
          Enum.map(neighbors, fn x -> 
            k = List.first(Map.keys(x))
            [%{:name => k, :neighbors => x[k], :gossip_limit => info}] end
          ) |> Enum.concat
        {nbs, Gossip.Actor}
      algo == "push-sum" ->
        nbs =
        Enum.map(neighbors, fn x -> 
            k = List.first(Map.keys(x))
            [%{:name => k, :neighbors => x[k], :eps => info}] end
          ) |> Enum.concat
        {nbs, Gossip.PushSumActor}
    end
  end
end
