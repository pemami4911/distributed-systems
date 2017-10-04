defmodule Gossip.Actor do
@moduledoc """
Nodes in the graphs. Listens for 
incoming rumors and propagates rumors until
reaches a receive limit.
"""
  require Logger
  use GenServer 

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [{:name, {:global, args[:name]}}])
  end

  def init(args) do
    # args contains the name and neighbors
    state = %{:args => args, :rumor => '', :recv_count => 0, :send_count => 0}
    state = gossip(1, state)
    {:ok, state}
  end

  defp gossip(delta_t, state) do
    # check if no more neighbors!
    if length(state[:args][:neighbors]) == 0 do
      Logger.debug "#{state[:args][:name]} terminating because neighbors are all dead!"
      GenServer.cast({:global, :main}, {:done, %{}}) 
      state
    else
      # if have the rumor, randomly select neighbor
      # to send to
      new_state = 
        if state[:recv_count] > 0 do
          recipient = Enum.take_random(state[:args][:neighbors], 1)
            |> List.first
          Logger.debug "#{state[:args][:name]} is gossiping to #{recipient} with send count #{state[:send_count]} and receive count #{state[:recv_count]}"
          GenServer.cast({:global, recipient}, {:rumor, state[:rumor]})
          
          %{:args => state[:args],
          :rumor => state[:rumor],
          :recv_count => state[:recv_count],
          :send_count => state[:send_count] + 1}
        else
          state
        end

      # reschedule if recv_count < N
      # otherwise send a msg indicating done
      cond do
        state[:send_count] >= state[:args][:gossip_limit] * 3 ->
          Logger.debug "#{state[:args][:name]} timed out with send count #{state[:send_count]} and receive count #{state[:recv_count]}"
          GenServer.cast({:global, :main}, {:done, %{}})
          broadcast_death(state, state[:args][:neighbors])
        state[:recv_count] < state[:args][:gossip_limit] ->
          Process.send_after(self(), :gossip, delta_t)
        true ->
          # Don't continue to schedule
          GenServer.cast({:global, :main}, {:done, %{}}) 
          broadcast_death(state, state[:args][:neighbors])        
      end
      new_state
    end
  end

  @doc """
  Callback to send out another rumor and schedule 
  the next broadcast
  """
  def handle_info(:gossip, state) do
     # Update the send count
    state = gossip(1, state)
    {:noreply, state}    
  end

  @doc """
  Callback for sending the number of received msgs
  """
  def handle_call(:check_recv, _from, state) do
    {:reply, state[:recv_count], state}
  end

  @doc """
  Other actors call this method to send this Actor 
  a rumor
  """
  def handle_cast({:rumor, rumor}, state) do
    # Update the recv count
    state = %{:args => state[:args],
      :rumor => rumor,
      :recv_count => state[:recv_count] + 1,
      :send_count => state[:send_count]}
    {:noreply, state}
  end

  def handle_cast({:death, neighbor}, state) do
    # remove the dead neighbor from list of neighbors
    nbs = List.delete(state[:args][:neighbors], neighbor)
    args = %{:name => state[:args][:name],
      :neighbors => nbs, :gossip_limit => state[:args][:gossip_limit]}
    state = %{:args => args,
      :rumor => state[:rumor],
      :recv_count => state[:recv_count],
      :send_count => state[:send_count]}

    {:noreply, state}
  end

  def broadcast_death(state, [neighbor | neighbors]) when length(neighbors) > 0 do
    GenServer.cast({:global, neighbor}, {:death, state[:args][:name]})
    broadcast_death(state, neighbors)
  end

  def broadcast_death(state, [neighbor]) do
    GenServer.cast({:global, neighbor}, {:death, state[:args][:name]})
  end


end