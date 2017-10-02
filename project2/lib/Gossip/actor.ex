defmodule Gossip.Actor do
@moduledoc """
Nodes in the graphs. Listens for 
incoming rumors and propagates rumors until
reaches a receive limit.
"""
  use GenServer 

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [{:name, {:global, args[:name]}}])
  end

  def init(args) do
    # args contains the name and neighbors
    state = %{:args => args, :rumor => '', :recv_count => 0}
    gossip(1, state)    
    {:ok, state}
  end

  defp gossip(delta_t, state) do
    # if have the rumor, randomly select neighbor
    # to send to
    if state[:recv_count] > 0 do
      #IO.puts "to_string(#{state[:args][:name]}) is gossiping"
      recipient = Enum.take_random(state[:args][:neighbors], 1)
      GenServer.cast({:global, List.first(recipient)}, {:rumor, state[:rumor]})
    end

    # reschedule if recv_count < N
    # otherwise send a msg indicating done
    if state[:recv_count] < state[:args][:gossip_limit] do
      Process.send_after(self(), :gossip, delta_t)
    #else
      # Don't continue to schedule
      #GenServer.cast(state[:args][:main], {:done, %{}}) 
    end
  end

  @doc """
  Callback to send out another rumor and schedule 
  the next broadcast
  """
  def handle_info(:gossip, state) do
    gossip(1, state)
    {:noreply, state}
  end

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
      :recv_count => state[:recv_count] + 1}
    {:noreply, state}
  end

end