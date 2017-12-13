defmodule TwitterWeb.UserController do
  use TwitterWeb, :controller
  alias Twitter.Repo

  plug :scrub_params, "user" when action in [:create]

  def show(conn, %{"id" => username}) do
    redirect(conn, to: session_path(conn, :show, username))
  end
  
  def new(conn, params) do
    changeset = Twitter.User.changeset(%Twitter.User{}, params)
    render conn, "new.html", changeset: changeset
  end
  
  def create(conn, %{"user" => user_params}) do
    IO.inspect user_params
    changeset = %Twitter.User{} |> Twitter.User.registration_changeset(user_params)
    res = Repo.insert(changeset)
    case res do
      {:ok, user} ->
        conn
        |> redirect(to: user_path(conn, :show, user_params["username"]))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

end
