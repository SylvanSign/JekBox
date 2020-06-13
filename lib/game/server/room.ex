defmodule Game.Server.Room do
  use GenServer, restart: :temporary
  defstruct [:room, pids: MapSet.new()]

  # Client API
  def start_link(room) do
    GenServer.start_link(__MODULE__, room, name: room)
  end

  def state(room) do
    GenServer.call(room, :state)
  end

  def register(room, pid) do
    GenServer.call(room, {:register, pid})
  end

  # Server Callbacks
  @impl true
  def init(room) do
    {:ok, %__MODULE__{room: room}}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:register, pid}, _from, state) do
    {:reply, :ok, register_pid(state, pid)}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    IO.puts("Room dropping #{inspect(pid)}")

    case forget_pid(state, pid) do
      :shutdown ->
        {:stop, :shutdown, state}

      state ->
        {:noreply, state}
    end
  end

  # Private Helpers
  defp register_pid(%__MODULE__{pids: pids} = state, pid) do
    Process.monitor(pid)
    %__MODULE__{state | pids: MapSet.put(pids, pid)}
  end

  defp forget_pid(%__MODULE__{pids: pids}, pid) do
    case MapSet.size(pids) do
      1 ->
        :shutdown

      _ ->
        %__MODULE__{pids: MapSet.delete(pids, pid)}
    end
  end
end
