defmodule Game.JekBox.Bot do
  use GenServer

  def start_link(room_pid, room, id) do
    GenServer.start_link(__MODULE__, {room_pid, room, id})
  end

  def init({room_pid, room, id}) do
    send(self(), {:register, room, id})
    {:ok, room_pid}
  end

  def handle_info({:register, room, id}, room_pid) do
    name = "#{Game.Server.RoomCodes.new()} BOT"
    {:ok, _state} = Game.Server.Room.register_bot(room_pid, id, name)
    GameWeb.Endpoint.subscribe(room)
    IO.puts(">>>>>>>> initialized #{name}")
    {:noreply, room_pid}
  end

  def handle_info(%{event: "state", payload: %{state: %{step: :write_clues}}}, room_pid) do
    IO.puts(">>>>>>>> need to write_clues")
    {:noreply, room_pid}
  end

  def handle_info(event, room_pid) do
    IO.puts(">>>>>>>> BOT GOT EVENT #{inspect(event)}")
    {:noreply, room_pid}
  end
end
