defmodule GameWeb.PageController do
  use GameWeb, :controller

  def home(conn, _params) do
    render(conn, "home.html")
  end

  def new(conn, _params) do
    room = Game.Rooms.new()

    conn
    |> put_session(:room, room)
    |> redirect(to: Routes.page_path(conn, :room, room))
  end

  def join(conn, _params) do
    render(conn, "join.html")
  end

  def room(conn, %{"room" => room}) do
    case get_session(conn, :name) do
      nil ->
        render(conn, "name.html", room: room)

      name ->
        render(conn, "lobby.html", room: room, name: name)
    end
  end

  def name(conn, %{"form" => %{"name" => name}}) do
    name = String.upcase(name)

    conn
    |> put_session(:name, name)
    |> redirect(to: Routes.page_path(conn, :new))
  end
end
