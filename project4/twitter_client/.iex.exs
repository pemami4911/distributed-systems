import Twitter.Client

name = to_string(Enum.take_random(97..122, 8))
name_ = name |> String.to_atom
args = [username: name_, main: nil] 

n = args[:username] 
  |> Atom.to_string
my_name = n <> "@127.0.0.1" |> String.to_atom

server = "engine@127.0.0.1"
    |> String.to_atom

Node.start(my_name)
Node.set_cookie(:"pemami")

# Connect to the engine
IO.puts("Connecting to engine from #{Node.self}")
case Node.connect(server) do
  true ->
    :global.sync()
  reason ->
    IO.puts "Could not connect to #{server}, reason: #{reason}"
    System.halt(0)
end


{:ok, client} = Twitter.Client.start_link(args)