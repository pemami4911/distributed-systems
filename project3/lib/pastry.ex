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
    
    # add all nodes to the network
    add_all(opts[:numNodes], opts)
    IO.puts "Finished building DHT"
    # store a bunch of items in the DHT
    store_all(opts[:numNodes])
    IO.puts "Finished storing items in DHT"

    {_, num_hops} = GenServer.call({:global, hash("0")},
        {:get, %{:key => hash(item(opts[:numNodes])), :hops => 0}})

    IO.puts "num hops: #{num_hops}: log N: #{:math.log(opts[:numNodes])}"

    # main loop
    receive do
      {:done, _msg} ->
        IO.puts "Done"
        System.halt(0)
    end
  end

  def add_all(n, opts) do   
    for i <- 0..n do
      next_node_id = i
      last_node_id = i - 1
      hashed_id = hash(Integer.to_string(next_node_id))
      hashed_last_id = hash(Integer.to_string(last_node_id))

      opts_ = opts ++ [id: hashed_id]
      {:ok, _} = Pastry.Node.start_link(opts_)
      
      IO.puts "node #{hashed_id} has joined the network"

      if i > 0 do
        # send the join message
        path = GenServer.call({:global, 
          hashed_last_id},
          {:join, hashed_id})

        # add each id in the path to the new node
        Enum.map(path, fn x -> GenServer.cast({:global, hashed_id}, {:announce_arrival, x}) end)
        # Have the new node alert everyone in its tables of its prescense
        GenServer.call({:global, hashed_id}, {:update_all_after_join})
      end    
    end
  end

  def store_all(n) do
    hashed_id = hash("0")
    for i <- 0..n do
      v = item(i)
      GenServer.call({:global, hashed_id},
        {:store, %{:key => hash(v), :value => v}})
    end
  end

  def item(id) do
    "item" <> Integer.to_string(id)    
  end

  def hash(x) do
    Base.encode16(:crypto.hash(:sha, x))
  end

end
