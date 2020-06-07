defmodule GameWeb.Login do
  use GameWeb, :controller
  import Phoenix.LiveView.Controller

  def index(conn, _params) do
    name = get_session(conn, "name")
    room = get_session(conn, "room")

    render(conn, "index.html", name: name, room: room)
  end

  def login(conn, %{"login" => %{"room" => room, "name" => name}}) do
    conn
    |> put_session("room", room)
    |> put_session("name", name)
    |> live_render(GameWeb.GameLive,
      session: %{
        "room" => room,
        "name" => name
      }
    )
  end
end
