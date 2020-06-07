defmodule GameWeb.GameLive do
  use GameWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, started: false, room: "", name: "")}
  end

  def handle_event("inc", _event, socket) do
    {:noreply, assign(socket, c: socket.assigns.c + 1)}
  end

  def handle_event(
        "play",
        %{"login" => %{"name" => name, "room" => room}},
        %{assigns: %{started: false}} = socket
      ) do
    {:noreply, assign(socket, room: room, name: name, started: true)}
  end
end
