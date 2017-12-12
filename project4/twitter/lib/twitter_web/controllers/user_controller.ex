defmodule TwitterWeb.UserController do
  use TwitterWeb, :controller
  alias Twitter.Repo

  plug :scrub_params, "user" when action in [:create]

  def show(conn, %{"id" => id}) do
    user = Repo.get!(Twitter.User, id)
    redirect(conn, session_path(conn, :show, user))
  end
  
  def new(conn, params) do
    changeset = Twitter.User.changeset(%Twitter.User{}, params)
    render conn, "new.html", changeset: changeset
  end
  
  def create(conn, %{"user" => user_params}) do
    changeset = %Twitter.User{} |> Twitter.User.registration_changeset(user_params)
    res = Repo.insert(changeset)
    IO.inspect res

    case res do
      {:ok, user} ->
        conn
        |> put_flash(:info, "#{user.username} created!")
        |> redirect(to: user_path(conn, :show, user))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

end
