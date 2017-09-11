defmodule Bitcoin.Boss do
    @moduledoc """
    Documentation for Bitcoin.
    """  
    use Supervisor

    def start_link(opts) do
      Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
    end

    def init(opts) do
      # start workers
      case opts[:workers] do  
        :single -> 
          opts = opts ++ [chars: 6] 
          workers = build_workers([], 1, opts)    
          Supervisor.init(workers, strategy: :one_for_one)
        :all ->
          n = System.schedulers_online()
          workers = build_workers([], n, opts)
          Supervisor.init(workers, strategy: :one_for_one)
      end 
    end 

    def build_workers(workers, n, opts) when n > 1 do
      opts_ = opts ++ [chars: n]
      workers = workers ++ [Supervisor.child_spec({Bitcoin.Miner, opts_}, id: n)]
      build_workers(workers, n - 1, opts)
    end

    def build_workers(workers, n, opts) do
      opts_ = opts ++ [chars: n]
      workers ++ [Supervisor.child_spec({Bitcoin.Miner, opts_}, id: n)]      
    end

  end
  