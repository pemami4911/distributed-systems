defmodule Bitcoin.Boss do
    @moduledoc """
    Documentation for Bitcoin.
    """  
    use Supervisor

    def start_link(opts) do
      Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
    end

    def init(opts) do
      # Set the node name and cookie
      my_name = "server@" <> opts[:ip] |> String.to_atom
      Node.start(my_name)
      Node.set_cookie(:"pemami")
      IO.puts "Starting server at #{Node.self}. Listening for new workers."

      # start workers
      n = System.schedulers_online()
      #opts_ = opts ++ [foreman: Bitcoin.Foreman]

      workers = build_workers([], n, opts)
      args = [{:n, n}, {:k, opts[:k]}]
      # start the "foreman"
      workers_ = workers ++ [Supervisor.child_spec({Bitcoin.Foreman, args}, id: n+1)]
      Supervisor.init(workers_, strategy: :one_for_one)
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
  