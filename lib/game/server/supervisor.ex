defmodule JekBox.Server.Supervisor do
  use Supervisor

  # Client API
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  # Server Callbacks
  @impl true
  def init(:ok) do
    children = [
      {JekBox.Server.Rooms, name: JekBox.Server.Rooms},
      {DynamicSupervisor, name: JekBox.Server.RoomSupervisor, strategy: :one_for_one},
      {JekBox.JekBox.Words, name: JekBox.JekBox.Words}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
