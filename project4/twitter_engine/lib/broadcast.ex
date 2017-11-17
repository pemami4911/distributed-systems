defmodule Twitter.Broadcast do
@moduledoc """
Implements a form of 1-to-many messaging in Elixir.
"""
use Task

def start_link(args) do
  Task.start_link(__MODULE__, :broadcast, [args])
end

@doc """
Sends out args[tweet] to every recipient in args[recipients].
"""
def broadcast(args) do
  for user <- args[:recipients] do
    GenServer.cast({:global, user}, {:tweet, args[:tweet]})
  end
end

end