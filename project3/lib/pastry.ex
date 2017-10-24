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
    pids = add_all(opts[:numNodes], opts)
    Logger.info "Finished building DHT"
    {:ok, gather} = Pastry.Gather.start_link(%{:pids => pids, :num_reqs => opts[:numRequests]})
    Logger.info "Started gather GenServer"

    # store a bunch of items in the DHT
    store_all(opts[:numNodes])
    Logger.info "Finished storing items in DHT"

    req_all(opts[:numNodes], opts[:numRequests])

    countdown(opts[:numRequests] + 1, opts[:numNodes], opts[:numRequests])

    avg_hops = GenServer.call(gather, :gather)
    Logger.info "average hops per item retrieval: ~#{Float.round(avg_hops, 2)}. Log(#{opts[:numNodes]}) = #{Float.round(:math.log(opts[:numNodes]), 2)}"
  end

  def add_all(n, opts) do  
    Enum.map(0..n, fn i ->
      next_node_id = i
      last_node_id = i - 1
      hashed_id = hash(Integer.to_string(next_node_id))
      hashed_last_id = hash(Integer.to_string(last_node_id))

      opts_ = opts ++ [id: hashed_id]
      {:ok, pid} = Pastry.Node.start_link(opts_)
      
      #Logger.debug "Adding #{hashed_id} to the network"

      if i > 0 do
        # send the join message
        data = %{:key => hashed_id, :path => []}
        path = GenServer.call({:global, 
          hashed_last_id},
          {:join, data})
        
        # add each id in the path to the new node
        Enum.map(path, fn x -> GenServer.cast({:global, hashed_id}, {:announce_arrival, x}) end)
        # Have the new node alert everyone in its tables of its prescense
        GenServer.call({:global, hashed_id}, :update_all_after_join)
      end
      pid
    end)
  end

  def store_all(n) do
    hashed_id = hash("0")
    for i <- n..2*n do
      v = item(i)
      GenServer.call({:global, hashed_id},
        {:store, %{:key => hash(v), :value => v}})
    end
  end

  @doc """
  n: number of nodes in network
  r: number of requests to make
  """
  def req_all(n, r) do
    for i <- 0..n do
      Process.send(GenServer.whereis({:global, hash(Integer.to_string(i))}), {:make_reqs, r}, [])
    end
  end

  def item(id) do
    "item" <> Integer.to_string(id)    
  end

  def hash(x) do
    Base.encode16(:crypto.hash(:sha, x))
  end

  def countdown(n, n_nodes, n_reqs) do
    if n > 0 do
      Logger.info "[#{n}] sending #{n_reqs} queries to the DHT from #{n_nodes} peers..."      
      :timer.sleep(1000)
      countdown(n - 1, n_nodes, n_reqs)
    end
  end

end
