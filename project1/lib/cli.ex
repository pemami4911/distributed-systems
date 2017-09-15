defmodule Bitcoin.CLI do
  # use Application

  def main(args) do
    {opts,_,_} = OptionParser.parse(args, switches: [k: :integer, server: :string])
    IO.inspect(opts)
    Bitcoin.Boss.start_link(opts)
    receive do
      { :until_death } ->
        System.halt(0)
    end
  end

end