defmodule GameWeb.PageController do
  use GameWeb, :controller
  alias Game.Server.Rooms
  import Phoenix.LiveView.Controller

  def play(conn, _) do
    render(conn, "play.html")
  end

  # TODO make a more intuitve "name change" workflow
  def home(conn, %{"change" => _}) do
    render(conn, "name.html", to: Routes.page_path(conn, :home))
  end

  def home(conn, _params) do
    case get_session(conn, :name) do
      nil ->
        render(conn, "name.html", to: Routes.page_path(conn, :home))

      name ->
        render(conn, "home.html", name: name)
    end
  end

  def name(conn, %{"form" => %{"name" => name, "to" => to}}) do
    name = String.upcase(name)

    conn
    |> put_session(:name, name)
    |> redirect(to: to)
  end

  def new(conn, _params) do
    room = Rooms.new()

    conn
    |> redirect(to: Routes.page_path(conn, :game, room))
  end

  def join(conn, _params) do
    render(conn, "join.html")
  end

  def join_room(conn, %{"form" => %{"room" => room}}) do
    room = Game.Util.transform_room(room)

    if Rooms.exists?(room) do
      conn
      |> redirect(to: Routes.page_path(conn, :game, room))
    else
      conn
      |> put_flash(:error, "Cannot find room #{room}")
      |> redirect(to: Routes.page_path(conn, :join))
    end
  end

  def game(conn, %{"room" => room}) do
    room = Game.Util.transform_room(room)

    case get_session(conn, :name) do
      nil ->
        render(conn, "name.html", to: Routes.page_path(conn, :game, room))

      _ ->
        if Rooms.exists?(room) do
          live_render(conn, GameWeb.GameLive, session: %{"room" => room})
        else
          redirect(conn, to: Routes.page_path(conn, :home))
        end
    end
  end
end
