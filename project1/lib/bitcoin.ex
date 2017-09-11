defmodule Bitcoin do
  use Application

  def start(_type, args) do
    Bitcoin.Boss.start_link(args)
  end

end