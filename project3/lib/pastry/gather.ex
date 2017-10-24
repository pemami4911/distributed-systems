defmodule Pastry.Gather do
    @moduledoc """
    Essentially performs an MPI Gather to count average number of hops
    """

    use GenServer

    def start_link(args) do
        GenServer.start_link(__MODULE__, args, [{:name, {:global, "gather"}}])
    end

    @doc """
    args should be a list of the PIDs of all of the nodes in the network
    """
    def init(args) do
        state = %{:pids => args[:pids], :num_reqs => args[:num_reqs]}
        {:ok, state}
    end

    @doc """
    Compute the average
    """
    def handle_call(:gather, _from, state) do
        sum_total_hops = Enum.reduce(state[:pids], 0, fn (pid, acc) -> 
            s = GenServer.call(pid, :get_state)
            s[:total_hops] + acc
        end)
        avg = sum_total_hops / (length(state[:pids]) * state[:num_reqs])
        {:reply, avg, state}
    end

end