defmodule Gossip.GossipAlgo do
  @moduledoc """
  The Gossip algorithm. 

    2. Start the supervisor that brings up all nodes 
    3. Tell one node the "rumor" 
    4. When a node has "heard" the rumor N times, it should stop transmitting
  """  
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [{:name, {:global, :main}}])
  end

  def init(args) do
    {:ok, %{:num_finished => 0, :N => args[:numNodes], :top_level => args[:topLevel]}}
  end

  def handle_call({:start_rumor, rumor}, _from, state) do
    GenServer.cast({:global, 1}, {:rumor, rumor})
    {:reply, :ok, state}
  end

  def handle_cast({:done, %{}}, state) do    
    new_state = %{:num_finished => state[:num_finished] + 1, :N => state[:N], :top_level => state[:top_level]}
    if new_state[:num_finished] == new_state[:N] do
       send(new_state[:top_level], {:done, %{}})
    end
    {:noreply, new_state}
  end

end