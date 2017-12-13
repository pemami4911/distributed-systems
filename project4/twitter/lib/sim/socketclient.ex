defmodule Twitter.SocketClient do
  @moduledoc false
  require Logger
  alias Phoenix.Channels.GenSocketClient
  @behaviour GenSocketClient

  def start_link(opts) do
    GenSocketClient.start_link(
          __MODULE__,
          Phoenix.Channels.GenSocketClient.Transport.WebSocketClient,
          Keyword.put(opts, :url, "ws://localhost:4000/socket/websocket")
        )
  end

  def init(opts) do
    {:connect, opts[:url], [], %{:username => opts[:username],
      :TL => [], :status => :active, :transition => opts[:transition]}}
  end

  # def init(url) do
  #     {:connect, url, [], %{}} 
  # end

  ## WEBSOCKET CALLBACKS
  def handle_connected(transport, state) do
    Logger.debug("connecting")
    GenSocketClient.join(transport, "twitter:" <> state[:username])
    {:ok, state}
  end

  def handle_disconnected(reason, state) do
    Logger.error("disconnected: #{inspect reason}")
    Process.send_after(self(), :connect, :timer.seconds(1))
    {:ok, state}
  end

  def handle_joined(topic, _payload, _transport, state) do
    Logger.info("joined the topic #{topic}")
    {:ok, state}
  end

  def handle_join_error(topic, payload, _transport, state) do
    Logger.error("join error on the topic #{topic}: #{inspect payload}")
    {:ok, state}
  end

  def handle_reply("new_tweet", _ref, %{"status" => "ok"} = payload, _transport, state) do
    Logger.info("server pong #{inspect payload}")
    {:ok, state}
  end

  def handle_reply(topic, _ref, payload, _transport, state) do
    Logger.warn("reply on topic #{topic}: #{inspect payload}")
    {:ok, state}
  end

  def handle_channel_closed(topic, payload, _transport, state) do
    Logger.error("disconnected from the topic #{topic}: #{inspect payload}")
    {:ok, state}
  end

  def handle_message(topic, event, payload, _transport, state) do
    Logger.warn("message on topic #{topic}: #{event} #{inspect payload}")
    display_and_store(payload, state)
    {:ok, state}
  end

  def handle_info(:connect, _transport, state) do
    Logger.info("connecting")
    {:connect, state}
  end

  def handle_info({:join, topic}, transport, state) do
    Logger.info("joining the topic #{topic}")
    case GenSocketClient.join(transport, topic) do
      {:error, reason} ->
        Logger.error("error joining the topic #{topic}: #{inspect reason}")
        Process.send_after(self(), {:join, topic}, :timer.seconds(1))
      {:ok, _ref} -> :ok
    end

    {:ok, state}
  end
  
  def handle_info(:tweet, transport, state) do
    send_tweet(transport, state[:username], "testtest")
    {:ok, state}
  end

  def handle_info({:follow_all, their_usernames}, transport, state) do
    Enum.each(their_usernames, fn u_name ->
      follow(transport, u_name)
    end)
    {:ok, state}
  end

  def handle_info({:sim, client, tp, rt_prob}, transport, state) do
    if state[:status] == :active do
      roll = :rand.uniform
      if roll > rt_prob do
        # send next tweet
        # shoot off a random tweet
        len = :rand.uniform(20)
        text = to_string(Enum.take_random(97..122, len))
        send_tweet(transport, state[:username], text)
      else
        # do a random RT
        rand_tweet = Enum.take_random(state[:TL], 1) |> Enum.at(0)
        retweet(transport, rand_tweet[:uid], state)
      end
    end

    tmp = tp + :rand.normal(0, 0.1)   
    next = 
      if tmp < 0.01 do
        0.01
      else
        tmp
      end

    # do a status transition 
    roll = :rand.uniform
    state = 
      if state[:status] == :active do
        # change status to inactite
        state = if roll > Enum.at(Enum.at(state[:transition], 0), 0) do
          #Logger.info("@#{state[:username]} Logging off")
          Map.replace(state, :status, :inactive)
        else
          state
        end
        state
      else
        state = if roll > Enum.at(Enum.at(state[:transition], 1), 1) do
          #Logger.info("@#{state[:username]} Logging on")
          Map.replace(state, :status, :active)
          else
            state
          end
      end  

    Process.send_after(client, {:sim, client, tp, rt_prob}, round(next * 1000))
    {:ok, state}
  end

  def handle_info(message, _transport, state) do
    Logger.warn("Unhandled message #{inspect message}")
    {:ok, state}
  end
  
  # EXTERNAL API #
  def simulate_activity(client, tweet_period, rt_prob) do
    Process.send(client, {:sim, client, tweet_period, rt_prob}, [])
  end

  ## TODO: REMOVE
  def test(client) do
    Process.send(client, :sim, [])
  end

  def follow_all(client, their_usernames) do
    Process.send(client, {:follow_all, their_usernames}, [])
  end

  ## INTERNAL API STUFF
  def send_tweet(transport, username, text) do
    uid = get_tweet_uid(username, text)
    tweet = %{:author => username, :uid => uid, :body => text}
    GenSocketClient.push(transport, "twitter:" <> username, "new_tweet", tweet)
  end

  @doc """
  Search through the TL, find the tweet with the uid, and then send it out.
  """
  def retweet(transport, tweet_uid, state) do
    tweet = Enum.find(state[:TL], fn tweet ->
      if tweet[:uid] == tweet_uid do
        true
      else
        false
      end
    end)
    if tweet != nil do
      name_string = tweet[:author] |> Atom.to_string 
      text = "(RT) @" <> name_string <> ": " <> tweet[:body]    
      send_tweet(transport, state[:username], text)
    else
      Logger.error("@#{state[:username]} couldn't locate tweet by uid, unable to RT")
    end
  end

  @doc """
  Return all tweets in TL containing substring "query"
  """
  def search(state, query) do
    Enum.filter(state[:TL], fn tweet -> 
      if String.contains?(tweet[:body], query) do
        tweet[:body]
      end
    end)
  end

  defp follow(transport, their_username) do
    GenSocketClient.join(transport, "twitter:" <> their_username)
  end

  # defp unfollow(transport, their_username) do
  #   GenSocketClient.leave(transport, "twitter:" <> their_username)
  # end

  defp display_and_store(tweet, state, display \\ true) do
    # append username to front of tweet. 
    t = prepare_tweet(tweet)
    if display do
      Logger.debug(t)
    end
    Map.replace(state, :TL, [t | state[:TL]])
  end

  defp get_tweet_uid(username, tweet) do
    timestamp = :os.system_time(:milli_seconds)
      |> Integer.to_string
     Base.encode16(:crypto.hash(:sha256, username <> timestamp <> tweet))
  end

  # defp transport(state),
  #   do: Map.take(state, [:transport_mod, :transport_pid, :serializer])
  
  defp prepare_tweet(tweet) do
    "@" <> tweet["author"] <> ": " <> tweet["body"]
  end
end