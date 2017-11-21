defmodule Twitter.Client.CLI do
  
  def main(args) do 
    {opts, _, _} = OptionParser.parse(args, switches: [config: :string])
    opts_ = opts ++ [main: self()]

    Twitter.Sim.init(opts_)
    
    receive do
      {:done, _msg} ->
        System.halt(0)
    end
  end

end