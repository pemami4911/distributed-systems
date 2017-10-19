defmodule Pastry.Node do
    @moduledoc """
    A peer node in the Pastry overlay network
    sends reqs at 1 req/sec

    generate nodeIDs and keys with 
        > Base.encode16(:crypto.hash(:sha, ""))

        - left neighbor
        - right neighbor
        - finger table
            - leaf set
            - routing table
        - nodeID
        - map (K,V)
        - app
        - send leaf set
        - send routing table row
        - update leaf set
        - update routing table
        - join?
    """
    require Logger
    use GenServer

    def start_link(args) do
        node_id = Base.encode16(:crypto.hash(:sha, args[:id]))
        GenServer.start_link(__MODULE__, [], [{:name, {:global, node_id}}])
    end

    def init(_args) do
        state = %{:map => %{}, :left_n => '', :right_n => '', :finger_table => %{}} 
        {:ok, state}
    end
end