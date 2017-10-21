defmodule Pastry.App do
    @moduledoc """
    Application API

    Brings up each node of the network 1 by 1
    (i.e., successive joins)

    """
    use Supervisor

    def start_link(args) do
        Supervisor.start_link(__MODULE__, args, name: __MODULE__)
    end

    def init(_args) do
        # for each node in range(numNodes)
        # Enum.map(1..args[:numNodes], fn ->
        #     {:ok, next_pid} = Supervisor.start_child(self(), {Pastry.Node, args})
        #     join(next_pid, prev_pid)
        #     prev_pid = next_pid
        # end)
        {:ok, %{}}
    end

end