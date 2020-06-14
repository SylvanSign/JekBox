defmodule GameWeb.GameLive do
  use GameWeb, :live_view
  alias Game.Server.Rooms
  alias Game.Server.Room

  @impl true
  def mount(:not_mounted_at_router, %{"room" => room, "name" => name}, socket) do
    socket =
      assign(socket,
        room: room,
        name: name,
        state: %{}
      )

    if connected?(socket) do
      room_pid = Rooms.pid(room)
      GameWeb.Endpoint.subscribe(room)
      Room.register(room_pid, name)

      {:ok, assign(socket, room_pid: room_pid)}
    else
      {:ok, socket}
    end
  end

  @impl true
  def handle_event("start", _event, socket) do
    Room.start(socket.assigns.room_pid)

    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "state", payload: %{state: state}}, socket) do
    {:noreply,
     assign(socket,
       state: state
     )}
  end
end
