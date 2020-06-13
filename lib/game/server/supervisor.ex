defmodule Game.Server.Supervisor do
  use Supervisor

  # Client API
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  # Server Callbacks
  @impl true
  def init(:ok) do
    children = [
      {Game.Server.Rooms, name: Game.Server.Rooms},
      {DynamicSupervisor, name: Game.Server.RoomSupervisor, strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
