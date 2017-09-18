defmodule Bitcoin.Foreman do
  @moduledoc """
    Listens for incoming requests of workers to connect 
    and assigns new work
  """
  use GenServer
  
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [{:name, {:global, Bitcoin.Foreman}}])
  end

  @doc """
    Maintains a map of the units of work being done by different workers 
  """
  def init(args) do
    {:ok, args}
  end

  def handle_call({:request_work, cores, node_name}, _from, state) do
    IO.puts("registering new worker #{to_string(node_name)}")

    resp = [{:n, state[:n] + cores}, {:k, state[:k]}]
    workers = Bitcoin.Boss.build_workers([], resp[:n], state[:n], resp)
    Node.spawn_link(node_name, Bitcoin.Remote, :run, [workers])
    {:reply, true, resp}
  end

  def handle_cast({:found_coin, coin}, state) do
    IO.puts(coin)
    {:noreply, state}
  end

end