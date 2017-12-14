defmodule TwitterWeb.FollowController do
  use TwitterWeb, :controller
  alias Twitter.Repo
  alias Twitter.User

  def index(conn, %{"user" => username}) do
    # try to get user by unique username from DB
    user = Repo.get_by(User, username: username)
    cond do
      # User was found
      user -> 
        conn 
          |> send_resp(200, "Avail")
      true ->
        conn
          |> send_resp(200, "Unavail")
    end
  end

end