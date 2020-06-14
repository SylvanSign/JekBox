defmodule Game.Server.Rooms do
  use GenServer

  @chars String.codepoints("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
  @length_of_room_name 4

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

  def exists?(room) do
    GenServer.call(__MODULE__, {:exists?, room})
  end

  def pid(room) do
    GenServer.call(__MODULE__, {:pid, room})
  end

  # Server Callbacks
  @impl true
  def init(:ok) do
    {:ok, Map.new()}
  end

  @impl true
  def handle_call(:state, _from, rooms) do
    {:reply, rooms, rooms}
  end

  @impl true
  def handle_call(:new, _from, rooms) do
    {room, rooms} = create_room(rooms)
    {:reply, room, rooms}
  end

  @impl true
  def handle_call({:exists?, room}, _from, rooms) do
    {:reply, room_exists?(rooms, room), rooms}
  end

  @impl true
  def handle_call({:pid, room}, _from, rooms) do
    {:reply, Map.get(rooms, room), rooms}
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

    {:ok, room_pid} =
      DynamicSupervisor.start_child(Game.Server.RoomSupervisor, {Game.Server.Room, room})

    Process.monitor(room_pid)
    {room, Map.put(rooms, room, room_pid)}
  end

  defp room_exists?(rooms, room) do
    Map.has_key?(rooms, room)
  end

  defp delete_room(rooms, room) do
    Map.delete(rooms, room)
  end

  defp get_unique_room_name(rooms, name \\ generate_new_name(), tries \\ 0) do
    unless Map.has_key?(rooms, name) do
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
  end
end
