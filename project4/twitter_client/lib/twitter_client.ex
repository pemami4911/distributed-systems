defmodule Twitter.Client do
  @moduledoc """
  Documentation for Twitter.Client.
  """
  use GenServer
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [{:name, {:global, self()}}])
  end

  def init(args) do
    # Check that the user is registered already, if not - register
    register(args)
    {:ok, %{:main => args[:main], :username => args[:username],
      :TL => []}}
  end

  # Callbacks
  def handle_cast({:tweet, tweet}, state) do
    state = display_and_store(tweet, state)
    {:noreply, state}
  end

  # API
  def login(client) do
    state = :sys.get_state(client) 
    case GenServer.call({:global, Twitter.Engine}, {:auth, state[:username]}) do
      :ok ->
        Logger.info("Logged in successfully")
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
    tweet = %{:uid => uid, :body => text}
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
      send_tweet(client, tweet[:body])
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

  def follow(their_username) do
    if GenServer.call({:global, Twitter.Engine}, {:subscribe, their_username}) != :ok do
      Logger.error("Unable to follow user #{their_username |> Atom.to_string()}, maybe they aren't registered yet?")
    else
      Logger.info("Followed #{their_username |> Atom.to_string()}")
    end
  end

  def unfollow(their_username) do
    if GenServer.call({:global, Twitter.Engine}, {:unsubscribe, their_username}) != :ok do
      Logger.error("Unable to unfollow user #{their_username |> Atom.to_string()}, maybe they aren't registered yet?")
    else
      Logger.info("Unfollowed #{their_username |> Atom.to_string()}")
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
    Logger.info(tweet[:body])
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
