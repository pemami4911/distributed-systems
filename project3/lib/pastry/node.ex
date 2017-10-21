defmodule Pastry.Node do
    @moduledoc """
    A peer node in the Pastry overlay network
    
    sends reqs at 1 req/sec to either
    get/store a (K,V)

    generate nodeIDs and keys with 
        > Base.encode16(:crypto.hash(:sha, ""))

        - left neighbor
        - right neighbor
        - finger table
            - leaf set
            - routing table
        - nodeID
        - map (K,V)
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
        GenServer.start_link(__MODULE__, args, [{:name, {:global, node_id}}])
    end

    def init(args) do
        id = Base.encode16(:crypto.hash(:sha, args[:id]))
        IO.puts id
        {:ok, %{
            #:id => Base.encode16(:crypto.hash(:sha, args[:id])),
            :id => id,
            :num_reqs => args[:numRequests],
            :map => %{},
            :left_n => '',
            :right_n => '',
            :finger_table => %{}}} 
    end

    @doc """
    store a new key value pair 
    """
    def handle_call({:store, kv}, _from, state) do
        {:ok, %{
            :id => state[:id],
            :num_reqs => state[:num_reqs],
            :map => Map.put(state[:map], kv[:key], kv[:value]),
            :left_n => state[:left_n],
            :right_n => state[:right_n],
            :finger_table => state[:finger_table]}}    
    end

    def handle_cast({:join, key}, state) do
        # Send back state
        GenServer.cast({:global, key}, {:update_state, state[:finger_table]})
        # route message
        route({:join, key})
    end

    def route({:join, key}) do
        
    end
end