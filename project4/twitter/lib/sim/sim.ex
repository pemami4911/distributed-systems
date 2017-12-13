defmodule Twitter.Sim do
@moduledoc """
Various helper fns for running Twitter simulations
"""
  require Logger

  def init(opts) do
    # Parse the config file
    cfg = parse_config(List.first(opts))
    u_names = generate_usernames(parse_int(cfg["users"]))
    #IO.inspect u_names
    
    # Status transition map
    #           active inactive
    # activate [ 0.95    0.05  ]
    # inactive [ 0.1     0.9   ]

    transition = [[parse_float(cfg["active"]), 1 - parse_float(cfg["active"])],
                 [1 - parse_float(cfg["inactive"]), parse_float(cfg["inactive"])]]

    # Bring up all clients, returning a list of all of the PIDs
    clients = 
      Enum.map(u_names, fn u_name -> 
        args = init_user(u_name, transition)
        {:ok, pid} = Twitter.SocketClient.start_link(args)
        pid
      end)
    
    # Have each client login and then follow others
    # compute the clients with topK # of followers
    topk = followers(clients, u_names, cfg)

    topk_tweet_period = 
      if parse_int(cfg["topk_freq"]) > 100 do
        1 / (parse_float(cfg["tweet_freq"]) * (parse_float(cfg["topk_freq"]) / 100))
      else
        1 / parse_float(cfg["tweet_freq"])
      end
    # Have each client start tweeting
    reg_tweet_period = 1 / parse_float(cfg["tweet_freq"])
    sim_start(clients, topk, reg_tweet_period, topk_tweet_period)
    cfg["experiment"]
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
  defp init_user(name, transition) do
    #name_ = name |> String.to_atom
    [username: name, transition: transition] 
  end

  # Allocate followers according to Zipf distribution
  defp followers(clients, usernames, cfg) do
    # for each client
    client_followers = 
      Enum.map(clients, fn client -> 
        # My username
        state = :sys.get_state(client)
        my_name = state[:username] |> Atom.to_string
        # randomly sample from Zipf distribution
        n_fllwrs = round(Twitter.Sim.Zipf.sample(parse_int(cfg["users"]), 
          parse_float(cfg["skew"])))
        # randomly sample n_fllwrs uniformly from usernames
        # remove yourself if you are in u_names
        u_names = 
          Enum.take_random(usernames, n_fllwrs)
            |> Enum.take_while(fn n -> n != my_name end)
        
        # follow each of them
        Twitter.SocketClient.follow_all(client, u_names)
        {client, n_fllwrs}
      end)
    # return the topK clients in terms of # followers
    Enum.sort_by(client_followers, fn {_client, n_fllwrs} -> n_fllwrs end)
      |> Enum.take(3)
      |> Enum.map(fn {client, _n_fllwrs} -> client end)
  end

  defp sim_start(clients, topk, reg_tp, topk_tp) do
    Enum.each(clients, fn client ->
      if Enum.member?(topk, client) do
        # send over the topk tweet period (higher freq) and retweet prob of 1%
        Twitter.SocketClient.simulate_activity(client, topk_tp, 0.01)
      else
        Twitter.SocketClient.simulate_activity(client, reg_tp, 0)
      end
    end)
  end

end