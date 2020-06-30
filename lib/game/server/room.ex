defmodule Game.Server.Room do
  use GenServer, restart: :temporary
  alias Game.JekBox.State

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
    GenServer.call(room, {:register, id, name, false})
  end

  def register_bot(room, id, name) do
    GenServer.call(room, {:register, id, name, true})
  end

  def start(room) do
    GenServer.call(room, :start)
  end

  def restart(room) do
    GenServer.call(room, :restart)
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

  def bot(room) do
    GenServer.call(room, :bot)
  end

  # Server Callbacks
  @impl true
  def init(room) do
    state = State.new(room)
    pids = %{}
    timer = Process.send_after(self(), :close_if_empty, @timeout)
    humans = 0

    {:ok, {state, pids, humans, timer}}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:register, id, name, bot?}, {pid, _}, {state, pids, humans, timer} = all_state) do
    if State.allowed_to_register?(state, id) do
      Process.cancel_timer(timer)

      {state, _pids, _humans, _timer} =
        all_state =
        {state, pids, humans, timer}
        |> register_pid(pid, id, name, bot?)
        |> broadcast_state()

      {:reply, {:ok, state}, all_state}
    else
      {:reply, {:error, "Can't join game since it's already in progress"}, all_state}
    end
  end

  @impl true
  def handle_call(:start, _from, {state, pids, humans, timer}) do
    new_state =
      {State.start(state), pids, humans, timer}
      |> broadcast_state()

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:restart, _from, {state, pids, humans, timer}) do
    new_state =
      {State.restart(state), pids, humans, timer}
      |> broadcast_state()

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:clue, clue}, {pid, _}, {state, pids, humans, timer}) do
    id = pids[pid]

    new_state =
      {State.clue(state, id, clue), pids, humans, timer}
      |> broadcast_state()

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:toggle_duplicate, clue}, _from, {state, pids, humans, timer}) do
    new_state =
      {State.toggle_duplicate(state, clue), pids, humans, timer}
      |> broadcast_state()

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:done_clues, _from, {state, pids, humans, timer}) do
    new_state =
      {State.done_clues(state), pids, humans, timer}
      |> broadcast_state()

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:guess, guess}, _from, {state, pids, humans, timer}) do
    new_state =
      {State.guess(state, guess), pids, humans, timer}
      |> broadcast_state()

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:pass, _from, {state, pids, humans, timer}) do
    new_state =
      {State.pass(state), pids, humans, timer}
      |> broadcast_state()

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:right, _from, {state, pids, humans, timer}) do
    new_state =
      {State.right(state), pids, humans, timer}
      |> broadcast_state()

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:wrong, _from, {state, pids, humans, timer}) do
    new_state =
      {State.wrong(state), pids, humans, timer}
      |> broadcast_state()

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:bot, _from, {%{room: room} = state, pids, humans, timer}) do
    {:ok, _pid} = Game.JekBox.Bot.start_link(self(), room, System.unique_integer())
    {:reply, :ok, {state, pids, humans, timer}}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    state =
      state
      |> forget_pid(pid)
      |> broadcast_state()

    {:noreply, state}
  end

  @impl true
  def handle_info(:close_if_empty, {_state, pids, _timer} = state)
      when map_size(pids) > 0 do
    {:noreply, state}
  end

  @impl true
  def handle_info(:close_if_empty, state) do
    IO.puts("shutting down")
    {:stop, :shutdown, state}
  end

  # Private Helpers
  defp register_pid({state, pids, humans, timer}, pid, id, name, bot?) do
    humans =
      unless bot? do
        IO.puts(">>>>>>>> registering nonbot #{inspect(pid)}")
        Process.monitor(pid)
        humans + 1
      else
        IO.puts(">>>>>>>> registering BOT #{inspect(pid)}")
        humans
      end

    {State.register_id(state, id, name), Map.put(pids, pid, id), humans, timer}
  end

  defp forget_pid({state, pids, humans, timer}, pid) do
    id = pids[pid]
    state = State.forget_id(state, id)
    pids = Map.delete(pids, pid)
    # must be human, since bots won't disconnect without crashing room through link
    humans = humans - 1

    timer =
      if humans == 0 do
        IO.puts("will close room")
        Process.send_after(self(), :close_if_empty, @timeout)
      else
        timer
      end

    {state, pids, humans, timer}
  end

  defp broadcast_state({%{broadcast: true} = state, pids, humans, timer}) do
    GameWeb.Endpoint.broadcast!(state.room, "state", %{state: state})
    {state, pids, humans, timer}
  end

  defp broadcast_state({%{broadcast: false} = state, pids, humans, timer}) do
    {state, pids, humans, timer}
  end
end
