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
  def login(username) do 
    case GenServer.call({:global, Twitter.Engine}, {:auth, username}) do
      :ok ->
        Logger.info("Logged in successfully")
      :error -> 
        Logger.error("Unable to verify account")
    end
  end
  
  def send_tweet(username, text) do
    # check length
    len = String.length(text)
    if len > 200 do
      Logger.error("Tweet is #{200 - len} chars too long")
    else 
      # generate uid
      uid = get_tweet_uid(username, text)
      tweet = %{:uid => uid, :body => text}
      GenServer.cast({:global, Twitter.Engine}, {:publish, {username, tweet}})
    end
    
  end

  def follow(their_username) do
    if GenServer.call({:global, Twitter.Engine}, {:subscribe, their_username}) != :ok do
      Logger.error("Unable to follow user #{their_username |> Atom.to_string()}, maybe they aren't registered yet?")
    else
      Logger.info("Followed #{their_username |> Atom.to_string()}")
    end
  end

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
