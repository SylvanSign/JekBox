defmodule GameWeb.PageController do
  use GameWeb, :controller
  alias Game.Server.Rooms

  # TODO make a more intuitve "name change" workflow
  def home(conn, %{"change" => _}) do
    render(conn, "name.html")
  end

  def home(conn, _params) do
    case get_session(conn, :name) do
      nil ->
        render(conn, "name.html")

      name ->
        case get_session(conn, :room) do
          nil ->
            render(conn, "home.html", name: name)

          room ->
            redirect(conn, to: Routes.page_path(conn, :lobby, room))
        end
    end
  end

  def name(conn, %{"form" => %{"name" => name}}) do
    name = String.upcase(name)

    conn
    |> put_session(:name, name)
    |> redirect(to: Routes.page_path(conn, :home))
  end

  def new(conn, _params) do
    room = Rooms.new()

    conn
    |> put_session(:room, room)
    |> redirect(to: Routes.page_path(conn, :lobby, room))
  end

  def join(conn, _params) do
    render(conn, "join.html")
  end

  def join_room(conn, %{"form" => %{"room" => room}}) do
    case Rooms.join(room) do
      :ok ->
        conn
        |> put_session(:room, room)
        |> redirect(to: Routes.page_path(conn, :lobby, room))

      :error ->
        conn
        |> put_flash(:error, "Cannot find room #{room}")
        |> redirect(to: Routes.page_path(conn, :join))
    end
  end

  def lobby(conn, %{"room" => room}) do
    if Rooms.exists?(room) do
      name = get_session(conn, :name)
      render(conn, "lobby.html", room: room, name: name)
    else
      conn
      |> put_session(:room, nil)
      |> put_flash(:error, "Cannot find room #{room}")
      |> redirect(to: Routes.page_path(conn, :home))
    end
  end

  def game(conn, %{"room" => room}) do
    render(conn, "game.html", room: room)
  end
end
