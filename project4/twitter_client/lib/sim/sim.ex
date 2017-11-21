defmodule Twitter.Sim do
@moduledoc """
Various helper fns for running Twitter simulations
"""
  require Logger

  def init(opts) do
    my_name = "sim@127.0.0.1" |> String.to_atom

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

    # Parse the config file
    cfg = parse_config(opts[:config])
    IO.inspect cfg
    u_names = generate_usernames(parse_int(cfg["users"]))
    
    # Bring up all clients, returning a list of all of the PIDs
    clients = 
      Enum.map(u_names, fn u_name -> 
        args = init_user(opts[:main], u_name)
        IO.inspect args
        {:ok, pid} = Twitter.Client.start_link(args)
        pid
      end)

    # Have each client login and then follow others
    followers(clients, u_names, cfg)

    # Have each client start tweeting
    tps = parse_int(cfg["tweets_per_sec"]) / parse_int(cfg["users"])

    if tps < 1.0 do
      Logger.error "TPS must be > 1"
      System.halt(0)
    end

    sim_start(clients, tps)
  end

  defp parse_int(x) do
    {y, _} = Integer.parse(x)
    y
  end

  defp parse_float(x) do 
    {y, _} = Float.parse(x)
    y
  end

  # Return a map, populated by the provided config file
  defp parse_config(fname) do
    File.read!(fname) 
      |> String.split("\n")
      |> Enum.reduce(%{}, fn item, map -> 
        s = String.split(item, "=")
        Map.put(map, List.first(s), List.last(s))
        end)
  end

  defp generate_usernames(n) do
    Enum.map(1..n, fn _ -> to_string(Enum.take_random(97..122, 8)) end)
  end

  # Args for initializing a Twitter client
  defp init_user(main, name) do
    name_ = name |> String.to_atom
    [username: name_, main: main] 
  end

  # Allocate followers according to Zipf distribution
  defp followers(clients, usernames, cfg) do
    # for each client
    Enum.map(clients, fn client -> 
      # login 
      Twitter.Client.login(client)
      # randomly sample from Zipf distribution
      n_fllwrs = round(Twitter.Sim.Zipf.sample(parse_int(cfg["users"]), 
        parse_float(cfg["skew"])))
      # randomly sample n_fllwrs uniformly from usernames
      u_names = Enum.take_random(usernames, n_fllwrs)
      # follow each of them
      Enum.map(u_names, fn u_name ->
        u_name_ = u_name |> String.to_atom
        Twitter.Client.follow(client, u_name_)
      end)
    end)
  end

  defp sim_start(clients, tps) do
    Enum.map(clients, fn client ->
      Twitter.Client.simulate_activity(client, tps) end)
  end

end