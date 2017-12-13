defmodule TwitterWeb.SessionController do
    use TwitterWeb, :controller
    import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]
    alias Twitter.Repo
    alias Twitter.User

    plug :scrub_params, "session" when action in ~w(create)a

    def new(conn, _params) do
        render conn, "new.html"
    end

    def show(conn, %{"id" => username}) do
        render conn, "show.html", username: username
    end

    def create(conn, %{"session" => %{"username" => username,
                                    "password" => password}}) do
        # try to get user by unique username from DB
        user = Repo.get_by(User, username: username)
        # examine the result
        result = cond do
            # if user was found and provided password hash equals to stored
            # hash
            user && checkpw(password, user.password_hash) ->
                {:ok, login(conn, user)}
                # else if we just found the use
            user ->
                {:error, :unauthorized, conn}
            # otherwise
            true ->
                # simulate check password hash timing
                dummy_checkpw
                {:error, :not_found, conn}
        end

        case result do
            {:ok, conn} ->
                conn
                #|> put_flash(:info, "You’re now logged in!")
                |> redirect(to: session_path(conn, :show, username))
            {:error, _reason, conn} ->
                conn
                |> put_flash(:error, "Invalid username/password combination")
                |> render("new.html")
        end
    end

    defp login(conn, user) do
        conn
        |> Guardian.Plug.sign_in(user)
    end
  
    def delete(conn, _) do
    # here will be an implementation
    end

end
