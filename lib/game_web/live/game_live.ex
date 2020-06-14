defmodule GameWeb.GameLive do
  use GameWeb, :live_view
  alias Game.Server.Rooms
  alias Game.Server.Room

  @impl true
  def mount(%{"room" => room}, %{"name" => name}, socket) do
    room = Game.Util.transform_room(room)

    unless Rooms.exists?(room) do
      {:ok, redirect(socket, to: Routes.page_path(socket, :home))}
    else
      if connected?(socket) do
        IO.puts("registering with #{room}")
        Room.register(room, name)
      end

      {:ok,
       assign(socket,
         room: room,
         name: name,
         state: :lobby
       )}
    end
  end

  @impl true
  def handle_event("start", _event, socket) do
    {:noreply,
     assign(socket,
       state: :game
     )}
  end
end
