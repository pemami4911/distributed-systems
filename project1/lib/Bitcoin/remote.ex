defmodule Bitcoin.Remote do

  def run(miners) do
    Bitcoin.Worker.start_link(miners)
    receive do
      { :until_death } ->
      System.halt(0)
    end
  end

  def connect(opts) do
    my_name = "worker@" <> opts[:ip] |> String.to_atom
    server = "server@" <> opts[:server] |> String.to_atom
    
    Node.start(my_name)
    # Connect to the server
    IO.puts("Connecting to server from #{Node.self}")
    Node.set_cookie(:"pemami")
    
    case Node.connect(server) do
      true ->
        :global.sync()
        #:global.whereis_name(Bitcoin.Foreman)
      reason ->
        IO.puts "Could not connect to #{server}, reason: #{reason}"
        System.halt(0)
    end
        
    n = System.schedulers_online()
    
    case GenServer.call({:global, Bitcoin.Foreman}, {:request_work, n, my_name}) do
      true ->
        IO.puts("starting workers!")
      reason ->
        IO.puts "Could not start workers, reason: #{reason}"
        System.halt(0)
    end
  end
end