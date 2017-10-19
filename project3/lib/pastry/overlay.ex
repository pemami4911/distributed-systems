defmodule Pastry.Overlay do
    @moduledoc """
    Supervisor for all peers in the network

    Supervisor.start_child() dynamically adds nodes 
    """
    require Logger
    use Supervisor

    def start_link(args) do
        Supervisor.start_link(__MODULE__, [], [{:name, {:global, node_id}}])
    end

    def init(_args) do
        Supervisor.init([], strategy: :one_for_one)
    end

    def join(node_id) do
        # initialize the overlay network with 1 node
        Supervisor.child_spec({Pastry.Node, %{id: node_id}})
        |> Supervisor.start_child(strategy: :one_for_one)
    end
end