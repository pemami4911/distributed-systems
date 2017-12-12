defmodule Twitter.SocketClient do
  @moduledoc false
  require Logger
  alias Phoenix.Channels.GenSocketClient
  @behaviour GenSocketClient

  def start_link() do
    GenSocketClient.start_link(
          __MODULE__,
          Phoenix.Channels.GenSocketClient.Transport.WebSocketClient,
          "ws://localhost:4000/socket/websocket"
        )
  end

  # def init(url) do
  #   {:connect, url, [], %{:main => args[:main], :username => args[:username],
  #     :TL => [], :status => :active, :transition => args[:transition]}}
  # end

  def init(url) do
      {:connect, url, [], %{}} 
  end

  ## WEBSOCKET API
  def handle_connected(transport, state) do
    Logger.info("connected")
    GenSocketClient.join(transport, "twitter:")
    state = Map.put(state, :transport, transport)
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

  def handle_channel_closed(topic, payload, _transport, state) do
    Logger.error("disconnected from the topic #{topic}: #{inspect payload}")
    {:ok, state}
  end

  def handle_message(topic, event, payload, _transport, state) do
    Logger.warn("message on topic #{topic}: #{event} #{inspect payload}")
    {:ok, state}
  end

  def handle_reply(topic, _ref, payload, _transport, state) do
    Logger.warn("reply on topic #{topic}: #{inspect payload}")
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
  
  def handle_info(message, _transport, state) do
    Logger.warn("Unhandled message #{inspect message}")
    {:ok, state}
  end

  def handle_info({:sim, client, tp, rt_prob}, state) do
    if state[:status] == :active do
      roll = :rand.uniform
      if roll > rt_prob do
        # send next tweet
        # shoot off a random tweet
        len = :rand.uniform(20)
        text = to_string(Enum.take_random(97..122, len))
        send_tweet(client, text, state)
      else
        # do a random RT
        rand_tweet = Enum.take_random(state[:TL], 1) |> Enum.at(0)
        retweet(client, rand_tweet[:uid], state)
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
          %{:main => state[:main],
          :username => state[:username],
          :TL => state[:TL],
          :status => :inactive,
          :transition => state[:transition]}
        else
          state
        end
        state
      else
        state = if roll > Enum.at(Enum.at(state[:transition], 1), 1) do
          #Logger.info("@#{state[:username]} Logging on")
          %{:main => state[:main],
          :username => state[:username],
          :TL => state[:TL],
          :status => :active,
          :transition => state[:transition]}
          else
            state
          end
      end  

    Process.send_after(client, {:sim, client, tp, rt_prob}, round(next * 1000))
    {:noreply, state}
  end

  ## TWITTER STUFF ##
  def simulate_activity(client, tweet_period, rt_prob) do
    Process.send(client, {:sim, client, tweet_period, rt_prob}, [])
  end

  def login(client) do
    state = :sys.get_state(client) 
    case GenServer.call({:global, Twitter.Engine}, {:auth, state[:username]}) do
      :ok ->
        Logger.debug("@#{state[:username]} logged in successfully")
      :error -> 
        Logger.error("@#{state[:username]} unable to verify account")
    end
  end
  
  def send_tweet(client, text, state \\ nil) do
    curr_state = 
      if state == nil do
        :sys.get_state(client)
      else
        state
      end 
    # generate uid
    uid = get_tweet_uid(curr_state[:username], text)
    tweet = %{:author => curr_state[:username], :uid => uid, :body => text}
    GenSocketClient.push(curr_state[:transport], "new_tweet", "twitter:" <> curr_state[:username], curr_state)
  end

  @doc """
  Search through the TL, find the tweet with the uid, and then send it out.
  """
  def retweet(client, tweet_uid, state \\ nil) do
    curr_state = 
      if state == nil do
        :sys.get_state(client)
      else
        state
      end 
    tweet = Enum.find(curr_state[:TL], fn tweet ->
      if tweet[:uid] == tweet_uid do
        true
      else
        false
      end
    end)
    if tweet != nil do
      name_string = tweet[:author] |> Atom.to_string 
      text = "(RT) @" <> name_string <> ": " <> tweet[:body]    
      send_tweet(client, text, curr_state)
    else
      Logger.error("@#{state[:username]} couldn't locate tweet by uid, unable to RT")
    end
  end

  @doc """
  Display the top K from the TL 
  """
  def top_k(client, k) do
    state = :sys.get_state(client)
    Enum.slice(state[:TL], 0..k-1)
      |> Enum.map(fn tweet -> 
        prepare_tweet(tweet) |> Logger.info end)
  end

  @doc """
  Return all tweets in TL containing substring "query"
  """
  def search(client, query) do
    state = :sys.get_state(client)
    Enum.filter(state[:TL], fn tweet -> 
      if String.contains?(tweet[:body], query) do
        tweet[:body]
      end
    end)
  end

  def follow(client, their_username) do
    state = :sys.get_state(client)
    if GenServer.call({:global, Twitter.Engine}, {:subscribe, state[:username], their_username}) != :ok do
      Logger.error("@#{state[:username]} unable to follow user #{their_username |> Atom.to_string()}, maybe they aren't registered yet?")
    else
      Logger.debug("@#{state[:username]} followed @#{their_username |> Atom.to_string()}")
    end
  end

  def unfollow(client, their_username) do
    state = :sys.get_state(client)
    if GenServer.call({:global, Twitter.Engine}, {:unsubscribe, state[:username], their_username}) != :ok do
      Logger.error("U@#{state[:username]} unable to unfollow user #{their_username |> Atom.to_string()}, maybe they aren't registered yet?")
    else
      Logger.debug("@#{state[:username]} unfollowed #{their_username |> Atom.to_string()}")
    end
  end

  def delete_account(client) do
    state = :sys.get_state(client)
    if GenServer.call({:global, Twitter.Engine}, {:delete_user, state[:username]}) != :ok do
      Logger.error("@#{state[:username]} unable to delete user #{state[:username] |> Atom.to_string()}, maybe they aren't registered?")
    end
  end

  # Private functions
  defp register(args) do
    if GenServer.call({:global, Twitter.Engine}, {:add_user, args[:username]}) != :ok do
      Logger.error("Failed to register")
      Process.send(args[:main], :done, [])
    end
  end

  defp display_and_store(tweet, state, display \\ true) do
      # append username to front of tweet. 
    text = prepare_tweet(tweet)
    if display do
      Logger.debug(text)
    end
    %{:main => state[:main],
      :username => state[:username],
      :TL => [tweet | state[:TL]],
      :status => state[:status],
      :transition => state[:transition]}
  end

  defp prepare_tweet(tweet) do
    author = tweet[:author] |> Atom.to_string
    body = tweet[:body]
    "@" <> author <> ": " <> body
  end

  defp get_tweet_uid(username, tweet) do
    timestamp = :os.system_time(:milli_seconds)
      |> Integer.to_string
    user = Atom.to_string(username)
     Base.encode16(:crypto.hash(:sha256, user <> timestamp <> tweet))
  end
end