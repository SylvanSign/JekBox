defmodule GameWeb.PageController do
  use GameWeb, :controller
  alias Game.Server.Rooms

  # TODO make a more intuitve "name change" workflow
  def home(conn, %{"n" => _}) do
    render(conn, "name.html")
  end

  def home(conn, _params) do
    case get_session(conn, :name) do
      nil ->
        render(conn, "name.html")

      name ->
        render(conn, "home.html", name: name)
    end
  end

  def new(conn, _params) do
    room = Rooms.new()

    conn
    |> put_session(:room, room)
    |> redirect(to: Routes.page_path(conn, :room, room))
  end

  def join(conn, _params) do
    render(conn, "join.html")
  end

  def join_room(conn, %{"form" => %{"room" => room}}) do
    case Rooms.join(room) do
      :ok ->
        conn
        |> put_session(:room, room)
        |> redirect(to: Routes.page_path(conn, :room, room))

      :error ->
        conn
        |> put_flash(:error, "Cannot find room #{room}")
        |> redirect(to: Routes.page_path(conn, :join))
    end
  end

  def game(conn, %{"room" => room}) do
    render(conn, "game.html", room: room)
  end

  def room(conn, %{"room" => room}) do
    name = get_session(conn, :name)
    render(conn, "lobby.html", room: room, name: name)
  end

  def name(conn, %{"form" => %{"name" => name}}) do
    name = String.upcase(name)

    conn
    |> put_session(:name, name)
    |> redirect(to: Routes.page_path(conn, :home))
  end
end
