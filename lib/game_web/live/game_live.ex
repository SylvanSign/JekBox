defmodule GameWeb.GameLive do
  use GameWeb, :live_view
  alias Game.Server.Rooms
  alias Game.Server.Room

  @impl true
  def render(%{state: %{step: step}} = assigns) do
    GameWeb.GameView.render("#{step}_live.html", assigns)
  end

  @impl true
  def render(_) do
    GameWeb.GameView.render("loading.html")
  end

  @impl true
  def mount(:not_mounted_at_router, %{"room" => room, "name" => name, "id" => id}, socket) do
    socket =
      assign(socket,
        page_title: "Room: #{room}",
        room: room,
        id: id,
        name: name,
        clue_pending?: true,
        state: %{}
      )

    if connected?(socket) do
      room_pid = Rooms.pid(room)
      GameWeb.Endpoint.subscribe(room)

      case Room.register(room_pid, id, name) do
        {:ok, state} ->
          {:ok,
           assign(
             socket,
             room_pid: room_pid,
             state: state
           )}

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
  def handle_event("clue", %{"clue" => clues}, socket) do
    clues =
      clues
      |> Stream.map(&elem(&1, 1))
      |> Stream.map(&String.trim/1)
      |> Enum.map(&String.upcase/1)

    Room.clue(socket.assigns.room_pid, clues)
    {:noreply, assign(socket, clue_pending?: false)}
  end

  @impl true
  def handle_event("toggle_duplicate", %{"clue" => clue}, socket) do
    Room.toggle_duplicate(socket.assigns.room_pid, clue)
    {:noreply, socket}
  end

  @impl true
  def handle_event("done_clues", _event, socket) do
    Room.done_clues(socket.assigns.room_pid)
    {:noreply, socket}
  end

  @impl true
  def handle_event("pass", _event, socket) do
    Room.pass(socket.assigns.room_pid)
    {:noreply, socket}
  end

  @impl true
  def handle_event("guess", %{"guess" => %{"guess" => guess}}, socket) do
    guess =
      guess
      |> String.trim()
      |> String.upcase()

    Room.guess(socket.assigns.room_pid, guess)
    {:noreply, socket}
  end

  @impl true
  def handle_event("right", _event, socket) do
    Room.right(socket.assigns.room_pid)
    {:noreply, socket}
  end

  @impl true
  def handle_event("wrong", _event, socket) do
    Room.wrong(socket.assigns.room_pid)
    {:noreply, socket}
  end

  @impl true
  def handle_event("restart", _event, socket) do
    Room.restart(socket.assigns.room_pid)
    {:noreply, socket}
  end

  @impl true
  def handle_event("bot", _event, socket) do
    Room.bot(socket.assigns.room_pid)
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "state", payload: %{state: state}}, socket) do
    {:noreply,
     assign(socket,
       state: state,
       clue_pending?: true
     )}
  end
end
