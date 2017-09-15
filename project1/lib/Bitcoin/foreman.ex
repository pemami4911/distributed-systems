defmodule Bitcoin.Foreman do
  @moduledoc """
    Listens for incoming requests of workers to connect 
    and assigns new work
  """
  use GenServer
  
  def start_link(cores) do
    GenServer.start_link(__MODULE__, cores, [:name, :foreman])
  end

  @doc """
    Maintains a map of the units of work being done by different workers 
  """
  def init(cores) do
    {:ok, %{n: cores}}
  end

  def handle_call({:request_work, cores}, _from, work_units) do
    n = work_units[:n] + cores
    {:reply, n, %{n: n}}
  end

end