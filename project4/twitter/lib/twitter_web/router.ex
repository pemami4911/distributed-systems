defmodule TwitterWeb.Router do
  use TwitterWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["html", "json"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers    
  end

  scope "/", TwitterWeb do
    pipe_through :browser # Use the default browser stack

    get "/", LoginController, :index
    get "/hello", HelloController, :index
    get "/hello/:messenger", HelloController, :show
  end

  scope "/api", TwitterWeb do
    pipe_through :api

    resources "/users", UserController, only: [:new, :create]
    resources "/sessions", SessionController, only: [:show, :new, :create, :delete]
    post "/follow/:user", FollowController, :show
  end
end
