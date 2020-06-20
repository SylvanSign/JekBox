defmodule Game.Server.Room do
  use GenServer, restart: :temporary
  alias Game.JustOne.State

  @words 13
  @timeout 30_000

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
    GenServer.call(room, {:clue, clue})
  end

  def toggle_duplicate(room, clue) do
    GenServer.call(room, {:toggle_duplicate, clue})
  end

  def done_clues(room) do
    GenServer.call(room, :done_clues)
  end

  def guess(room, guess) do
    GenServer.call(room, {:guess, guess})
  end

  def pass(room) do
    GenServer.call(room, :pass)
  end

  def right(room) do
    GenServer.call(room, :right)
  end

  def wrong(room) do
    GenServer.call(room, :wrong)
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
  def handle_call({:register, id, name}, {pid, _}, {state, pids}) do
    if State.allowed_to_register?(state, id) do
      state =
        {state, pids}
        |> register_pid(pid, id, name)
        |> broadcast_state()

      {:reply, :ok, state}
    else
      {:reply, {:error, "Can't join game since it's already in progress"}, {state, pids}}
    end
  end

  @impl true
  def handle_call(:start, _from, {state, pids}) do
    new_state =
      {State.start(state), pids}
      |> broadcast_state()

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:clue, clue}, {pid, _}, {state, pids}) do
    id = pids[pid]

    new_state =
      {State.clue(state, id, clue), pids}
      |> broadcast_state()

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:toggle_duplicate, clue}, _from, {state, pids}) do
    new_state =
      {State.toggle_duplicate(state, clue), pids}
      |> broadcast_state()

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:done_clues, _from, {state, pids}) do
    new_state =
      {State.done_clues(state), pids}
      |> broadcast_state()

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:guess, guess}, _from, {state, pids}) do
    new_state =
      {State.guess(state, guess), pids}
      |> broadcast_state()

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:pass, _from, {state, pids}) do
    new_state =
      {State.pass(state), pids}
      |> broadcast_state()

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:right, _from, {state, pids}) do
    new_state =
      {State.right(state), pids}
      |> broadcast_state()

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:wrong, _from, {state, pids}) do
    new_state =
      {State.wrong(state), pids}
      |> broadcast_state()

    {:reply, :ok, new_state}
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
  def handle_info(:close_if_empty, {_, pids} = state)
      when map_size(pids) > 0 do
    {:noreply, state}
  end

  @impl true
  def handle_info(:close_if_empty, {%{room: room}, _pids} = state) do
    IO.puts("Room #{room} shutting down after timing out")
    {:stop, :shutdown, state}
  end

  # Private Helpers
  defp register_pid({state, pids}, pid, id, name) do
    Process.monitor(pid)
    {State.register_id(state, id, name), Map.put(pids, pid, id)}
  end

  defp forget_pid({state, pids}, pid) do
    id = pids[pid]
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
