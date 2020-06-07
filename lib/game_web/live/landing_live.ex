defmodule GameWeb.LandingLive do
  use GameWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
