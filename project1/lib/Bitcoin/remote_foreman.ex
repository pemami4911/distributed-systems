defmodule Bitcoin.RemoteForeman do
  use GenServer

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], [{:name, {:global, :remote_foreman}}])
  end

  def init([]) do
    {:ok, %{}}
  end

  def request_work(foreman, n) do
    GenServer.call(foreman, {:request_work, n})
  end    
end