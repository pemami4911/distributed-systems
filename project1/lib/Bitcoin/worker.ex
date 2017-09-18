defmodule Bitcoin.Worker do
  use Supervisor

  def start_link(miners) do
    Supervisor.start_link(__MODULE__, miners, name: __MODULE__)
  end

  def init(miners) do
    Supervisor.init(miners, strategy: :one_for_one)
  end

end
