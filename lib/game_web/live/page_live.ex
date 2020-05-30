defmodule GameWeb.PageLive do
  use GameWeb, :live_view

  @impl true
  def mount(_params, %{"name" => name, "room" => room}, socket) do
    if name == nil or name == "" or room == nil or room == "" do
      {:ok, redirect(socket, to: Routes.login_path(socket, :index))}
    else
      {:ok, assign(socket, count: 0, cash: 100, price: 10, value: 100, room: room, name: name)}
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, redirect(socket, to: Routes.login_path(socket, :index))}
  end

  @impl true
  def handle_event("buy", _event, socket) do
    price = socket.assigns.price + 1

    socket =
      socket
      |> assign(count: socket.assigns.count + 1)
      |> assign(cash: socket.assigns.cash - price)
      |> assign(price: price)
      |> assign(value: socket.assigns.cash + socket.assigns.count * price)

    {:noreply, socket}
  end

  @impl true
  def handle_event("sell", _event, socket) do
    price = socket.assigns.price - 1

    socket =
      socket
      |> assign(count: socket.assigns.count - 1)
      |> assign(cash: socket.assigns.cash + price)
      |> assign(price: price)
      |> assign(value: socket.assigns.cash + socket.assigns.count * price)

    {:noreply, socket}
  end
end
