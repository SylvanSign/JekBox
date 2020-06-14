defmodule Game.Server.Room do
  use GenServer, restart: :temporary
  alias Game.JustOne.State

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
    GenServer.call(room, {:register, name})
  end

  def start(room) do
    GenServer.call(room, :start)
  end

  def clue(room, clue) do
    clue =
      clue
      |> String.trim()
      |> String.upcase()

    GenServer.call(room, {:clue, clue})
  end

  def mark_duplicate(room, clue) do
    GenServer.call(room, {:mark_duplicate, clue})
  end

  # Server Callbacks
  @impl true
  def init(room) do
    :timer.send_after(@timeout, room, :close_if_empty)

    {:ok, Game.JustOne.State.new(room)}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:register, name}, {pid, _}, state) do
    {:reply, :ok,
     state
     |> register_pid(pid, name)
     |> broadcast_state()}
  end

  @impl true
  def handle_call(:start, _from, state) do
    {:reply, :ok,
     state
     |> State.start()
     |> broadcast_state()}
  end

  @impl true
  def handle_call({:clue, clue}, {pid, _}, state) do
    {:reply, :ok,
     state
     |> State.clue(pid, clue)
     |> broadcast_state()}
  end

  @impl true
  def handle_call({:mark_duplicate, clue}, _from, state) do
    {:reply, :ok,
     state
     |> State.mark_duplicate(clue)
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
  defp register_pid(state, pid, name) do
    Process.monitor(pid)
    State.register_pid(state, pid, name)
  end

  defp forget_pid(state, pid) do
    %{pids: pids} = state = State.forget_pid(state, pid)

    if map_size(pids) == 0 do
      :timer.send_after(@timeout, :close_if_empty)
    end

    state
  end

  defp broadcast_state(%{broadcast: true} = state) do
    GameWeb.Endpoint.broadcast!(state.room, "state", %{state: state})
    state
  end

  defp broadcast_state(%{broadcast: false} = state) do
    state
  end
end
