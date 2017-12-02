defmodule Twitter.Engine do
  @moduledoc """
  Documentation for Twitter.Engine.
  """
  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, :ok, [{:name, {:global, Twitter.Engine}}])
  end

  @doc """
  Initializes the Twitter Engine. The state is the PubSub topic list.
  """
  def init(status) do
    {status, %{:num_tweets_sent => 0, :topics => %{}}}
  end

  # Callbacks
  @doc """
  Publishes a tweet to all registered followers of `user`
  """
  def handle_cast({:publish, {user, tweet}}, state) do
    Twitter.Broadcast.start_link(%{:recipients => state[:topics][user],
      :tweet => tweet})
    
    state = %{:num_tweets_sent => state[:num_tweets_sent] + 1,
        :topics => state[:topics]} 

    {:noreply, state}
  end

  def handle_cast(:shutdown, state) do
    System.halt(0)
    {:noreply, state}
  end

  def handle_call(:tweet_count, _from, state) do
    {:reply, state[:num_tweets_sent], state}
  end

  @doc """
  Verifies a user attempting to log in.
  """
  def handle_call({:auth, user}, _from, state) do
    if Map.has_key?(state[:topics], user) do
      {:reply, :ok, state}
    else
      {:reply, :error, state}
    end
  end

  @doc """
  Adds `from` to the topic list of `user`.
  """
  def handle_call({:subscribe, requester, user}, _from, state) do
    {res, topics} = 
      try do
        Map.get_and_update!(state[:topics], user, fn fllwrs -> 
          {fllwrs, MapSet.put(fllwrs, requester)} end)
      rescue
        _ in KeyError -> {:error, state[:topics]}
      end

      state = %{:num_tweets_sent => state[:num_tweets_sent],
        :topics => topics} 

      if res == :error do
        IO.inspect state[:topics]
        {:reply, :error, state}
      else
        {:reply, :ok, state}
      end
  end

  @doc """
  Removes `from` from the topic list `user`
  """
  def handle_call({:unsusbscribe, requester, user}, _from, state) do
    {_, topics} = 
      try do
        Map.get_and_update!(state[:topics], user, fn fllwrs ->
          {fllwrs, MapSet.delete(fllwrs, requester)} end)
      catch
        _ -> {nil, state[:topics]}
      end
      
      state = %{:num_tweets_sent => state[:num_tweets_sent],
        :topics => topics} 

      {:reply, :ok, state}
  end

  def handle_call({:delete_user, user}, _from, state) do
    topics = Map.delete(state[:topics], user)
    
    state = %{:num_tweets_sent => state[:num_tweets_sent],
        :topics => topics} 

    {:reply, :ok, state}
  end

  @doc """
  Adds `user` as a new topic.
  """
  def handle_call({:add_user, user}, _from, state) do
    topics = Map.put_new(state[:topics], user, MapSet.new())
    
    state = %{:num_tweets_sent => state[:num_tweets_sent],
        :topics => topics} 

    {:reply, :ok, state}
  end
end
