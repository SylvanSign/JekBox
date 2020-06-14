defmodule GameWeb.GameLive do
  use GameWeb, :live_view
  alias Game.Server.Rooms
  alias Game.Server.Room

  @impl true
  def mount(:not_mounted_at_router, %{"room" => room, "name" => name}, socket) do
    socket =
      assign(socket,
        # TODO remove this and part of template before launch
        debug: true,
        # debug: false,
        room: room,
        name: name,
        state: %{}
      )

    if connected?(socket) do
      room_pid = Rooms.pid(room)
      GameWeb.Endpoint.subscribe(room)

      case Room.register(room_pid, name) do
        :ok ->
          {:ok, assign(socket, room_pid: room_pid)}

        {:error, error} ->
          {:ok,
           socket
           |> put_flash(:error, error)
           |> redirect(to: Routes.page_path(socket, :home))}
      end
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
  def handle_event("clue", %{"clue" => %{"clue" => clue}}, socket) do
    Room.clue(socket.assigns.room_pid, clue)
    {:noreply, socket}
  end

  @impl true
  def handle_event("remove_clue", %{"clue" => clue}, socket) do
    Room.mark_duplicate(socket.assigns.room_pid, clue)
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
