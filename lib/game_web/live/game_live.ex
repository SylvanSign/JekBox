defmodule GameWeb.GameLive do
  use GameWeb, :live_view
  alias Game.Server.Rooms
  alias Game.Server.Room

  @impl true
  def mount(:not_mounted_at_router, %{"room" => room, "name" => name}, socket) do
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

  @impl true
  def handle_event("start", _event, socket) do
    {:noreply,
     assign(socket,
       state: :game
     )}
  end
end
