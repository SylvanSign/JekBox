defmodule Game.Server.Room do
  use GenServer, restart: :temporary

  @timeout 5000

  # Client API
  def start_link(room) do
    GenServer.start_link(__MODULE__, room)
  end

  def state(room) when is_binary(room) do
    pid = Game.Server.Rooms.pid(room)
    GenServer.call(pid, :state)
  end

  def state(pid) when is_pid(pid) do
    GenServer.call(pid, :state)
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

    {:ok,
     %{
       room: room,
       pids: Map.new(),
       step: :lobby
     }}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:register, pid, name}, _from, state) do
    {:reply, :ok,
     state
     |> register_pid(pid, name)
     |> broadcast_state()}
  end

  @impl true
  def handle_call(:start, _from, state) do
    {:reply, :ok,
     state
     |> Map.merge(%{
       step: :game,
       phase: :write_clues,
       words: Game.JustOne.Words.new()
     })
     |> broadcast_state()}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    IO.puts("Room dropping #{inspect(pid)}")

    case forget_pid(state, pid) do
      :shutdown ->
        {:stop, :shutdown, state}

      state ->
        {:noreply,
         state
         |> broadcast_state()}
    end
  end

  @impl true
  def handle_info(:close_if_empty, %{pids: pids} = state)
      when map_size(pids) > 0 do
    {:noreply, state}
  end

  @impl true
  def handle_info(:close_if_empty, %{room: room} = state) do
    IO.puts("Room #{room} shutting down after timing out")
    {:stop, :shutdown, state}
  end

  # Private Helpers
  defp register_pid(%{pids: pids} = state, pid, name) do
    Process.monitor(pid)
    %{state | pids: Map.put(pids, pid, name)}
  end

  defp forget_pid(%{pids: pids} = state, pid) do
    pids = Map.delete(pids, pid)

    if map_size(pids) == 0 do
      :timer.send_after(@timeout, :close_if_empty)
    end

    %{state | pids: pids}
  end

  defp broadcast_state(state) do
    GameWeb.Endpoint.broadcast!(state.room, "state", %{state: state})
    state
  end
end
