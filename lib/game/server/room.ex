defmodule Game.Server.Room do
  use GenServer, restart: :temporary

  @timeout 5000

  defstruct [:room, pids: Map.new()]

  # Client API
  def start_link(room) do
    GenServer.start_link(__MODULE__, room)
  end

  def state(room) do
    GenServer.call(room, :state)
  end

  def register(room, name) do
    GenServer.call(room, {:register, self(), name})
  end

  def start(room) do
    GenServer.call(room, :start)
  end

  # Server Callbacks
  @impl true
  def init(room) do
    :timer.send_after(@timeout, room, :close_if_empty)
    {:ok, %__MODULE__{room: room}}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:register, pid, name}, _from, state) do
    {:reply, :ok, register_pid(state, pid, name)}
  end

  @impl true
  def handle_call(:start, _from, state) do
    IO.inspect(state)
    GameWeb.Endpoint.broadcast!(state.room, "state", %{state: :start})
    {:reply, :ok, state}
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

  @impl true
  def handle_info(:close_if_empty, %__MODULE__{pids: pids} = state)
      when map_size(pids) > 0 do
    {:noreply, state}
  end

  @impl true
  def handle_info(:close_if_empty, %__MODULE__{room: room} = state) do
    IO.puts("Room #{room} shutting down after timing out")
    {:stop, :shutdown, state}
  end

  # Private Helpers
  defp register_pid(%__MODULE__{pids: pids} = state, pid, name) do
    Process.monitor(pid)
    %__MODULE__{state | pids: Map.put(pids, pid, name)}
  end

  defp forget_pid(%__MODULE__{pids: pids} = state, pid) do
    pids = Map.delete(pids, pid)

    if map_size(pids) == 0 do
      :timer.send_after(@timeout, :close_if_empty)
    end

    %__MODULE__{state | pids: pids}
  end
end
