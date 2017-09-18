defmodule Bitcoin.Boss do
    @moduledoc """
    Documentation for Bitcoin.
    """  
    use Supervisor

    def start_link(opts) do
      Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
    end

    def init(opts) do
      # This is the server node
      workers = if not List.keymember?(opts, :server, 0) do
        # Set the node name and cookie
        #fname = :"server@10.136.196.158"
        my_name = "server@" <> opts[:ip] |> String.to_atom
        Node.start(my_name)
        Node.set_cookie(:"pemami")
        IO.puts "Starting server at #{Node.self}. Listening for new workers."

        # start workers
        n = System.schedulers_online()
        opts_ = opts ++ [foreman: Bitcoin.Foreman]

        workers = build_workers([], n, opts_)
        args = [{:n, n}, {:k, opts_[:k]}]
        # start the "foreman"
        workers ++ [Supervisor.child_spec({Bitcoin.Foreman, args}, id: n+1)]
      # This is a remote worker node
      else
        my_name = "worker@" <> opts[:ip] |> String.to_atom
        server = "server@" <> opts[:server] |> String.to_atom
        
        Node.start(my_name)
        # Connect to the server
        IO.puts("Connecting to server from #{Node.self}")
        Node.set_cookie(:"pemami")
        
        foreman = case Node.connect(server) do
          true ->
            :global.sync()
            :global.whereis_name(Bitcoin.Foreman)
          reason ->
            IO.puts "Could not connect to #{server}, reason: #{reason}"
            System.halt(0)
        end
          
        n = System.schedulers_online()
        
        resp = Bitcoin.RemoteForeman.request_work(foreman, n)
        # Request work from the Foreman
        IO.inspect resp

        opts_ = opts ++ [foreman: :remote_foreman]
        build_workers([], resp[:n], opts_)
      end
      Supervisor.init(workers, strategy: :one_for_one)
    end 

    def build_workers(workers, n, opts) when n > 1 do
      opts_ = opts ++ [chars: n + 5]
      workers = workers ++ [Supervisor.child_spec({Bitcoin.Miner, opts_}, id: n)]
      build_workers(workers, n - 1, opts)
    end

    def build_workers(workers, n, opts) do
      opts_ = opts ++ [chars: n + 5]
      workers ++ [Supervisor.child_spec({Bitcoin.Miner, opts_}, id: n)]      
    end

  end
  