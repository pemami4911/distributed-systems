defmodule Twitter.Engine.CLI do
    def main(args) do 
        Node.start(:"engine@127.0.0.1")
        Node.set_cookie(:"pemami")

        Twitter.Engine.start_link(args)
        IO.puts "Connected at #{Node.self}, starting Twitter Engine..."
        receive do
          {:done, _msg} ->
            System.halt(0)
        end
    end
end