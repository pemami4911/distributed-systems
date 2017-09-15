defmodule Bitcoin.RemoteForeman do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, [name: :remote_foreman])
  end

  def init(opts) do
    GenServer.call({:foreman, String.to_atom(opts[:server])}, {:request_work, opts[:n]})
  end
end