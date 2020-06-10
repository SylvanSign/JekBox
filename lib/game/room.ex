defmodule Game.Room do
  use GenServer, restart: :temporary

  def start_link(room) do
    GenServer.start_link(__MODULE__, room)
  end

  @impl true
  def init(room) do
    {:ok, room}
  end
end
