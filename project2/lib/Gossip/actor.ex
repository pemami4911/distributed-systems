defmodule Actor do
@moduledoc """
Nodes in the graphs. Listens for 
incoming rumors and propagates rumors until
reaches a receive limit.
"""
  use GenServer 

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [{:name, {:global, #TODO# }}])
  end

  def init(args) do
    # args contains the name and neighbors
    {:ok, args, rumor: [], recv_count: 0}
  end

  def gossip do
    # if have the rumor, randomly select neighbor
    # to send to
  end

  @doc """
  Other actors call this method to send a rumor
  """
  def handle_cast({:rumor, rumor}, state) do
    # Update the recv count
    # If the recv count reaches the max, stop transmitting 
    # and send a "done" signal to the main process
  end

end