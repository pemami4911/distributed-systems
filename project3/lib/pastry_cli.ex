defmodule Pastry.CLI do
  @moduledoc """
  Documentation for Pastry.
  """
  require Logger

  def main(args) do
    {opts, _, _} = OptionParser.parse(args, switches: [numRequests: :integer, numNodes: :integer])

    # input validation
    if opts[:numNodes] < 1 do
      Logger.error("The number of nodes in the network must be >= 1")
      System.halt(1)
    end

    if opts[:numRequests] < 1 do
      Logger.error("The number of requests must be >= 1")
      System.halt(1)
    end
    
    # main loop
    receive do
      {:done, _msg} ->
        IO.puts "Done"
        System.halt(0)
    end
  end
end
