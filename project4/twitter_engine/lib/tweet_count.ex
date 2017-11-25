defmodule Twitter.Engine.TweetCount do
  use GenServer
  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], [{:name, {:global, Twitter.Engine.TweetCount}}])
  end

  def init(_opts) do
    count()
    {:ok, %{:prev => 0}}
  end

  def handle_info(:count, state) do
    #resp = GenServer.call({:global, Twitter.Engine}, :tweet_count)
    ss = :sys.get_state({:global, Twitter.Engine})
    resp = ss[:num_tweets_sent]
    Logger.info("TPS: #{resp - state[:prev]}")
    Process.send_after(self(), :count, 1000)
    {:noreply, %{:prev => resp}}
  end

  def count do
    Process.send_after(self(), :count, 1000)
  end

end