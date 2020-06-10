defmodule GameWeb.HomeController do
  use GameWeb, :controller

  def home(conn, _params) do
    render(conn, "home.html")
  end

  def new(conn, _params) do
    room = GameWeb.Rooms.new()
    redirect(conn, to: Routes.live_path(conn, GameWeb.RoomLive, room))
  end

  def join(conn, _params) do
    render(conn, "join.html")
  end
end
