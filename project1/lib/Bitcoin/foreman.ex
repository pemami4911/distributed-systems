defmodule Bitcoin.Foreman do
  @moduledoc """
    Listens for incoming requests of workers to connect 
    and assigns new work
  """
  use GenServer
  
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [{:name, Bitcoin.Foreman}])
  end

  @doc """
    Maintains a map of the units of work being done by different workers 
  """
  def init(args) do
    {:ok, args}
  end

  def handle_call({:request_work, cores}, _from, state) do
    resp = [{:n, state[:n] + cores}, {:k, state[:k]}]
    {:reply, resp, resp}
  end

  def handle_cast({:found_coin, coin}, state) do
    IO.puts(coin)
    {:noreply, state}
  end

end