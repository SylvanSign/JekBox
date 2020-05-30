defmodule GameWeb.Login do
  use GameWeb, :controller

  def index(conn, _params) do
    name = get_session(conn, "name")
    room = get_session(conn, "room")

    if name == nil or name == "" or room == nil or room == "" do
      render(conn, "index.html", name: name)
    else
      redirect(conn, to: Routes.page_path(conn, :index))
    end
  end

  def login(conn, %{"login" => %{"room" => room, "name" => name}}) do
    conn
    |> put_session("room", room)
    |> put_session("name", name)
    |> redirect(to: Routes.page_path(conn, :index))
  end
end
