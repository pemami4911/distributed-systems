defmodule Gossip.CLI do
  @moduledoc """
  Documentation for Gossip. Application start.
  """
  
  def main(args) do
    {opts,_,_} = OptionParser.parse(args, switches: [numNodes: :integer, topology: :string, algorithm: :string])
    opts = opts ++ [topLevel: self()]

    # Build topology
    Gossip.Manager.start_link(opts)
    
    # Start Gossip
    t1 = :erlang.timestamp()
    GenServer.call({:global, :main}, {:start_rumor, "test"})
    
    receive do
      {:done, _msg} ->
        t2 = :erlang.timestamp()
        IO.puts "Time to convergence: #{:timer.now_diff(t2, t1) * 0.000001}"
        System.halt(0)
    end

  end
end
