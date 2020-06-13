defmodule Game.Server.Rooms do
  use GenServer

  @chars String.codepoints("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
  # TODO change to ~3-4
  @length_of_room_name 1

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def state do
    GenServer.call(__MODULE__, :state)
  end

  def new do
    GenServer.call(__MODULE__, :new)
  end

  # Server Callbacks
  @impl true
  def init(:ok) do
    {:ok, MapSet.new()}
  end

  @impl true
  def handle_call(:new, {from_pid, _ref}, rooms) do
    {room, rooms} = create_room(rooms)
    :ok = Game.Server.Room.register(room, from_pid)
    {:reply, room, rooms}
  end

  @impl true
  def handle_call(:state, _from, rooms) do
    {:reply, rooms, rooms}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, {room, _}, _reason}, rooms) do
    IO.puts("Rooms dropping room #{inspect(room)}")
    rooms = delete_room(rooms, room)
    {:noreply, rooms}
  end

  # Private Helpers
  defp create_room(rooms) do
    {:ok, room} = get_unique_room_name(rooms)
    {:ok, _} = DynamicSupervisor.start_child(Game.Server.RoomSupervisor, {Game.Server.Room, room})
    Process.monitor(room)
    {room, MapSet.put(rooms, room)}
  end

  defp delete_room(rooms, room) do
    MapSet.delete(rooms, room)
  end

  defp get_unique_room_name(rooms, name \\ generate_new_name(), tries \\ 0) do
    unless MapSet.member?(rooms, name) do
      {:ok, name}
    else
      unless tries > 1000 do
        get_unique_room_name(rooms, generate_new_name(), tries + 1)
      else
        raise "Exhausted on room name generation"
      end
    end
  end

  defp generate_new_name() do
    Enum.reduce(1..@length_of_room_name, [], fn _i, acc ->
      [Enum.random(@chars) | acc]
    end)
    |> Enum.join("")
    |> String.to_atom()
  end
end
