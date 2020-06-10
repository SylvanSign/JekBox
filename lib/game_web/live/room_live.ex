defmodule GameWeb.RoomLive do
  use GameWeb, :live_view

  @impl true
  def mount(%{"room" => room}, _session, socket) do
    IO.puts(room)
    {:ok, assign(socket, room: room)}
  end

  @impl true
  def render(assigns) do
    ~L"""
    <h1>Room: <%= @room %></h1>
    <button phx-click="foo">Click me</button>
    """
  end

  @impl true
  def handle_event("foo", _event, socket) do
    IO.puts("got foo")
    {:noreply, socket}
  end
end
