defmodule GameWeb.Router do
  use GameWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {GameWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", GameWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/new", PageController, :new
    get "/join", PageController, :join
    get "/name", PageController, :name
    get "/rooms/:room", PageController, :game

    post "/name", PageController, :name
    post "/join", PageController, :join_room

    get "/javascript", PageController, :javascript
  end

  # Other scopes may use custom stacks.
  # scope "/api", GameWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: GameWeb.Telemetry
    end
  end
end
