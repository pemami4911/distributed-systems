defmodule Pastry.CLI do
  @moduledoc """
  Documentation for Pastry.
  """
  require Logger

  def main(args) do
    {opts, _, _} = OptionParser.parse(args, switches: [numRequests: :integer, numNodes: :integer])
    opts = opts ++ [main: self()]

    # input validation
    if opts[:numNodes] < 1 do
      Logger.error("The number of nodes in the network must be >= 1")
      System.halt(1)
    end

    if opts[:numRequests] < 1 do
      Logger.error("The number of requests must be >= 1")
      System.halt(1)
    end
    
    add_all(opts[:numNodes], opts)

    # main loop
    receive do
      {:done, _msg} ->
        IO.puts "Done"
        System.halt(0)
    end
  end

  def add_all(n, opts) do
    last_node_id = 0
    
    for i <- 1..n do
      next_node_id = i
      opts_ = opts ++ [id: Integer.to_string(next_node_id)]
      {:ok, _} = Supervisor.start_link([{Pastry.Node, opts_}], strategy: :one_for_one)
      # join
      # Store an item in the new node
      item = "item" <> Integer.to_string(next_node_id)
      GenServer.call({:global,
        hash(Integer.to_string(next_node_id))},
        {:store, %{key => hash(item), value => item})
      
      if last_node_id > 0 do
        # TODO:
        GenServer.cast({global, 
        hash(Integer.to_string(last_node_id)),
        {:join, hash(Integer.to_string(next_node_id))}})
      end
        
    end
  end

  def hash(x) do
    Base.encode16(:crypto.hash(:sha, x))
  end

end
