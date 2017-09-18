defmodule Bitcoin.CLI do
  # use Application

  def main(args) do
    {opts,_,_} = OptionParser.parse(args, switches: [k: :integer, server: :string, ip: :string])
    if not List.keymember?(opts, :server, 0) do
      Bitcoin.Boss.start_link(opts)
      receive do
        { :until_death } ->
        System.halt(0)
      end
    else
      Bitcoin.Remote.connect(opts)
    end
  end

end