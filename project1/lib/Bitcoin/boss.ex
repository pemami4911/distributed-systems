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
        fname = :"server@10.245.36.29"
        res = Node.start(fname, :longnames)
        Node.set_cookie(:"pemami")

        # start workers
        n = System.schedulers_online()

        workers = build_workers([], n, opts)
        # start the "foreman"
        workers ++ [Supervisor.child_spec({Bitcoin.Foreman, n}, id: n+1)]
      # This is a remote worker node
      else
        fname = :"worker@10.136.196.158"
        Node.start(fname, :longnames)
        server = "server@" <> opts[:server]
        # Connect to the server
        IO.puts("Connecting to #{server} from #{Node.self}")
        Node.set_cookie(:"pemami")
        
        case Node.connect(String.to_atom(server)) do
          true -> :ok
          reason ->
            IO.puts "Could not connect to #{server}, reason: #{reason}"
            System.halt(0)
        end
        
        n = System.schedulers_online()
        # Request work from the Foreman
        work_unit = GenServer.call({:foreman, server}, {:request_work, n})
        IO.puts(work_unit)
        build_workers([], work_unit, opts)
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
  