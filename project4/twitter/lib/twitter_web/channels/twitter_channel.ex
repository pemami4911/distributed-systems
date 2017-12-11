defmodule TwitterWeb.TwitterChannel do
  use Phoenix.Channel

  def join("twitter:" <> user_channel, _message, socket) do
    {:ok, socket}
  end

  def handle_in("new_tweet", %{"body" => body}, socket) do
    broadcast! socket, "new_tweet", %{body: body}
    {:noreply, socket}
  end
end