defmodule GameWeb.GameLive do
  use GameWeb, :live_view
  alias Game.Server.Rooms
  alias Game.Server.Room

  @impl true
  def render(%{state: %{step: :lobby}} = assigns) do
    GameWeb.GameView.render("lobby_live.html", assigns)
  end

  @impl true
  def render(%{state: %{step: :write_clues}} = assigns) do
    GameWeb.GameView.render("write_clues_live.html", assigns)
  end

  @impl true
  def render(%{state: %{step: :compare_clues}} = assigns) do
    GameWeb.GameView.render("compare_clues_live.html", assigns)
  end

  @impl true
  def render(%{state: %{step: :guess}} = assigns) do
    GameWeb.GameView.render("guess_live.html", assigns)
  end

  @impl true
  def render(_) do
    GameWeb.GameView.render("loading.html")
  end

  @impl true
  def mount(:not_mounted_at_router, %{"room" => room, "name" => name}, socket) do
    socket =
      assign(socket,
        # TODO remove this and part of template before launch
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
    Room.guess(socket.assigns.room_pid, guess)
    {:noreply, socket}
  end

  @impl true
  def handle_event("correct", _event, socket) do
    Room.correct(socket.assigns.room_pid)
    {:noreply, socket}
  end

  @impl true
  def handle_event("incorrect", _event, socket) do
    Room.incorrect(socket.assigns.room_pid)
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