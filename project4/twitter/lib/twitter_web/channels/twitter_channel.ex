defmodule TwitterWeb.TwitterChannel do
  use Phoenix.Channel

  def join("twitter:" <> user_channel, _message, socket) do
    {:ok, socket}
  end

  def handle_in("new_tweet", tweet, socket) do
    broadcast! socket, "new_tweet", tweet
    {:noreply, socket}
  end
end