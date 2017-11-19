import Twitter.Client

name = to_string(Enum.take_random(97..122, 8))
my_name = name <> "@127.0.0.1"
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

name_ = name |> String.to_atom
opts = [username: name_, main: nil] 

{:ok, client} = Twitter.Client.start_link(opts)
