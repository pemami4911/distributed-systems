defmodule Twitter.Client do
  @moduledoc """
  Documentation for Twitter.Client.
  """
  use GenServer
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [{:name, {:global, args[:username]}}])
  end

  def init(args) do
    # Check that the user is registered already, if not - register
    register(args)
    {:ok, %{:main => args[:main], :username => args[:username],
      :TL => []}}
  end

  # Callbacks
  def handle_info({:sim, client, tps}, _state) do
    # schedule tweets to be sent during the next second
    rvs = Enum.map(1..tps, fn _ -> :rand.uniform end)
    sum = Enum.reduce(rvs, fn (y, acc) -> y + acc end)
    Enum.scan(rvs, 0, fn (rv, acc) ->
      next = (rv / sum) + acc
      Process.send_after(self(), {:rand_tweet, client}, next * 1000)
      next end)
    Process.send_after(self(), {:sim, client, tps}, 1000)
  end

  def handle_info({:rand_tweet, client}, _state) do
    # shoot off a random tweet
    len = :rand.uniform(200)
    text = to_string(Enum.take_random(97..122, len))
    send_tweet(client, text)
  end

  def handle_cast({:tweet, tweet}, state) do
    state = display_and_store(tweet, state)
    {:noreply, state}
  end

  # API
  @doc """
    Send/receive tweets, occasionally retweeting? 
  """
  def simulate_activity(client, tps) do
    Process.send_after(self(), {:sim, client, tps}, 1000)
  end

  def login(client) do
    state = :sys.get_state(client) 
    case GenServer.call({:global, Twitter.Engine}, {:auth, state[:username]}) do
      :ok ->
        Logger.debug("Logged in successfully")
      :error -> 
        Logger.error("Unable to verify account")
    end
  end

  def logout(client) do
    state = :sys.get_state(client) 
    Process.send(state[:main], :done, [])
  end
  
  def send_tweet(client, text) do
    state = :sys.get_state(client) 
    # generate uid
    uid = get_tweet_uid(state[:username], text)
    tweet = %{:author => state[:username], :uid => uid, :body => text}
    GenServer.cast({:global, Twitter.Engine}, {:publish, {state[:username], tweet}})
  end

  @doc """
  Search through the TL, find the tweet with the uid, and then send it out.
  """
  def retweet(client, tweet_uid) do
    state = :sys.get_state(client)
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
      send_tweet(client, text)
    else
      Logger.error("Couldn't locate tweet by uid, unable to RT")
    end
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
      Logger.error("Unable to follow user #{their_username |> Atom.to_string()}, maybe they aren't registered yet?")
    else
      Logger.debug("Followed #{their_username |> Atom.to_string()}")
    end
  end

  def unfollow(client, their_username) do
    state = :sys.get_state(client)
    if GenServer.call({:global, Twitter.Engine}, {:unsubscribe, state[:username], their_username}) != :ok do
      Logger.error("Unable to unfollow user #{their_username |> Atom.to_string()}, maybe they aren't registered yet?")
    else
      Logger.debug("Unfollowed #{their_username |> Atom.to_string()}")
    end
  end

  def delete_account(client) do
    state = :sys.get_state(client)
    if GenServer.call({:global, Twitter.Engine}, {:delete_user, state[:username]}) != :ok do
      Logger.error("Unable to delete user #{state[:username] |> Atom.to_string()}, maybe they aren't registered?")
    end
  end

  # Private functions
  defp register(args) do
    if GenServer.call({:global, Twitter.Engine}, {:add_user, args[:username]}) != :ok do
      Logger.error("Failed to register")
      Process.send(args[:main], :done, [])
    end
  end

  defp display_and_store(tweet, state) do
      # append username to front of tweet. 
    name_string = tweet[:author] |> Atom.to_string 
    text = "@" <> name_string <> ": " <> tweet[:body]
    Logger.debug(text)
    %{:main => state[:main],
      :username => state[:username],
      :TL => state[:TL] ++ [tweet]}
  end

  defp get_tweet_uid(username, tweet) do
    timestamp = :os.system_time(:milli_seconds)
      |> Integer.to_string
    user = Atom.to_string(username)
     Base.encode16(:crypto.hash(:sha256, user <> timestamp <> tweet))
  end
end
