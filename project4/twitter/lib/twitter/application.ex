defmodule Twitter.Application do
  use Application
  use Task

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, args) do
    import Supervisor.Spec
    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Twitter.Repo, []),
      # Start the endpoint when the application starts
      supervisor(TwitterWeb.Endpoint, []),
      # Start your own worker by calling: Twitter.Worker.start_link(arg1, arg2, arg3)
      #worker(Twitter.SocketClient, []),
    ]
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Twitter.Supervisor]
    Task.async(fn -> 
      :timer.sleep(3000)
      Twitter.Sim.init(["lib/sim/cfg/user_stress/1.txt"])
    end)
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    TwitterWeb.Endpoint.config_change(changed, removed)
    :ok
  end

end
