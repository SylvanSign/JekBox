defmodule Game.Server.Rooms do
  use GenServer

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
    rooms = %{}
    pids = %{}
    {:ok, {rooms, pids}}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call(:new, _from, state) do
    {room, state} = create_room(state)
    {:reply, room, state}
  end

  @impl true
  def handle_call({:exists?, room}, _from, {rooms, _pids} = state) do
    {:reply, room_exists?(rooms, room), state}
  end

  @impl true
  def handle_call({:pid, room}, _from, {rooms, _pids} = state) do
    {:reply, Map.get(rooms, room), state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, room_pid, _reason}, state) do
    state = delete_room_by_pid(state, room_pid)
    {:noreply, state}
  end

  # Private Helpers
  defp create_room({rooms, pids}) do
    {:ok, room} = get_unique_room_name(rooms)

    {:ok, room_pid} =
      DynamicSupervisor.start_child(Game.Server.RoomSupervisor, {Game.Server.Room, room})

    Process.monitor(room_pid)

    rooms = Map.put(rooms, room, room_pid)
    pids = Map.put(pids, room_pid, room)
    {room, {rooms, pids}}
  end

  defp room_exists?(rooms, room) do
    Map.has_key?(rooms, room)
  end

  defp delete_room_by_pid({rooms, pids}, room_pid) do
    room = Map.get(pids, room_pid)
    rooms = Map.delete(rooms, room)
    pids = Map.delete(pids, room_pid)
    {rooms, pids}
  end

  defp get_unique_room_name(rooms, tries \\ 0) do
    name = Game.Server.RoomCodes.new()

    unless Map.has_key?(rooms, name) do
      {:ok, name}
    else
      unless tries > 1000 do
        get_unique_room_name(rooms, tries + 1)
      else
        raise "Exhausted on room name generation"
      end
    end
  end
end
