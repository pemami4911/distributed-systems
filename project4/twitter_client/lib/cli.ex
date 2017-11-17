defmodule Twitter.Client.CLI do
  
  def main(args) do 
    {opts, _, _} = OptionParser.parse(args, switches: [username: :string, send: :boolean, follow: :string])
    name = opts[:username] |> String.to_atom
    args = [username: name] ++ [main: self()]

    {:ok, _pid} = connect(args)
    Twitter.Client.login(args[:username])

    if opts[:send] do
      Twitter.Client.send_tweet(args[:username], "this is my first tweet")
    else
      their_username = opts[:follow] |> String.to_atom
      Twitter.Client.follow(their_username)
    end

    receive do
      {:done, _msg} ->
        System.halt(0)
    end
  end

  def connect(opts) do
    my_name = opts[:username] |> Atom.to_string
    my_name = my_name <> "@127.0.0.1"
               |> String.to_atom

    server = "engine@127.0.0.1"
        |> String.to_atom
    
    Node.start(my_name)
    Node.set_cookie(:"pemami")
    
    # Connect to the engine
    IO.puts("Connecting to engine from #{Node.self}")
    case Node.connect(server) do
      true ->
        :global.sync()
        #:global.whereis_name(Bitcoin.Foreman)
      reason ->
        IO.puts "Could not connect to #{server}, reason: #{reason}"
        System.halt(0)
    end
            
    Twitter.Client.start_link(opts)
  end
end