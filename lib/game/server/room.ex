defmodule Game.Server.Room do
  use GenServer, restart: :temporary
  alias Game.JustOne.State

  @words 13
  @timeout 10_000

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

  def register(room, id, name) do
    GenServer.call(room, {:register, id, name})
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

  def toggle_duplicate(room, clue) do
    GenServer.call(room, {:toggle_duplicate, clue})
  end

  def done_clues(room) do
    GenServer.call(room, :done_clues)
  end

  def guess(room, guess) do
    guess =
      guess
      |> String.trim()
      |> String.upcase()

    GenServer.call(room, {:guess, guess})
  end

  def pass(room) do
    GenServer.call(room, :pass)
  end

  def correct(room) do
    GenServer.call(room, :correct)
  end

  def incorrect(room) do
    GenServer.call(room, :incorrect)
  end

  # Server Callbacks
  @impl true
  def init(room) do
    :timer.send_after(@timeout, room, :close_if_empty)

    {:ok, {Game.JustOne.State.new(room, @words), %{}}}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:register, id, name}, {pid, _}, state) do
    state =
      state
      |> register_pid(pid, id, name)
      |> broadcast_state()

    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:start, _from, {state, pids}) do
    state = State.start(state)
    broadcast_state({state, pids})
    {:reply, :ok, {state, pids}}
  end

  @impl true
  def handle_call({:clue, clue}, {pid, _}, state) do
    {:reply, :ok,
     state
     |> State.clue(pid, clue)
     |> broadcast_state()}
  end

  @impl true
  def handle_call({:toggle_duplicate, clue}, _from, state) do
    {:reply, :ok,
     state
     |> State.toggle_duplicate(clue)
     |> broadcast_state()}
  end

  @impl true
  def handle_call(:done_clues, _from, state) do
    {:reply, :ok,
     state
     |> State.done_clues()
     |> broadcast_state()}
  end

  @impl true
  def handle_call({:guess, guess}, _from, state) do
    {:reply, :ok,
     state
     |> State.guess(guess)
     |> broadcast_state()}
  end

  @impl true
  def handle_call(:pass, _from, state) do
    {:reply, :ok,
     state
     |> State.pass()
     |> broadcast_state()}
  end

  @impl true
  def handle_call(:correct, _from, state) do
    {:reply, :ok,
     state
     |> State.correct()
     |> broadcast_state()}
  end

  @impl true
  def handle_call(:incorrect, _from, state) do
    {:reply, :ok,
     state
     |> State.incorrect()
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
  defp register_pid({state, pids}, pid, id, name) do
    Process.monitor(pid)
    {State.register_id(state, id, name), Map.put(pids, pid, id)}
  end

  defp forget_pid({state, pids}, pid) do
    id = Map.get(pids, pid)
    %{ids: ids} = state = State.forget_id(state, id)

    if map_size(ids) == 0 do
      :timer.send_after(@timeout, :close_if_empty)
    end

    {state, Map.delete(pids, pid)}
  end

  defp broadcast_state({%{broadcast: true} = state, pids}) do
    GameWeb.Endpoint.broadcast!(state.room, "state", %{state: state})
    {state, pids}
  end

  defp broadcast_state({%{broadcast: false} = state, pids}) do
    {state, pids}
  end
end
