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
    {status, %{}}
  end

  # Callbacks
  @doc """
  Publishes a tweet to all registered followers of `user`
  """
  def handle_cast({:publish, {user, tweet}}, topics) do
    Twitter.Broadcast.start_link(%{:recipients => topics[user], :tweet => tweet})
    {:noreply, topics}
  end

  @doc """
  Verifies a user attempting to log in.
  """
  def handle_call({:auth, user}, _from, topics) do
    if Map.has_key?(topics, user) do
      {:reply, :ok, topics}
    else
      {:reply, :error, topics}
    end
  end

  @doc """
  Adds `from` to the topic list of `user`.
  """
  def handle_call({:subscribe, user}, from, topics) do
    {_, topics} = 
      try do
        {pid, _} = from
        Map.get_and_update!(topics, user, fn fllwrs -> 
          {fllwrs, MapSet.put(fllwrs, pid)} end)
      catch
        _ -> {nil, topics}
      end 
      {:reply, :ok, topics}
  end

  @doc """
  Removes `from` from the topic list `user`
  """
  def handle_call({:unsusbscribe, user}, from, topics) do
    {_, topics} = 
      try do
        {pid, _} = from
        Map.get_and_update!(topics, user, fn fllwrs ->
          {fllwrs, MapSet.delete(fllwrs, pid)} end)
      catch
        _ -> {nil, topics}
      end
      {:reply, :ok, topics}
  end

  def handle_call({:delete_user, user}, _from, topics) do
    topics = Map.delete(topics, user)
    {:reply, :ok, topics}
  end

  @doc """
  Adds `user` as a new topic.
  """
  def handle_call({:add_user, user}, _from, topics) do
    topics = Map.put_new(topics, user, MapSet.new())
    {:reply, :ok, topics}
  end
end
