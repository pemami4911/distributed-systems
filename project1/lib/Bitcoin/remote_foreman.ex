defmodule Bitcoin.RemoteForeman do
  use GenServer

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], [{:name, {:global, Bitcoin.RemoteForeman}}])
  end

  def init([]) do
    {:ok, %{}}
  end

  # CLIENT API

  def request_work(foreman, n) do
    GenServer.call({:global, foreman}, {:request_work, n})
  end    

end