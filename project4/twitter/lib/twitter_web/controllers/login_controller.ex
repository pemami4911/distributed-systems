defmodule TwitterWeb.LoginController do
  use TwitterWeb, :controller

  def index(conn, _params) do
    redirect conn, to: "/api/sessions/new"
  end
end
