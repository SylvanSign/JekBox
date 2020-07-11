defmodule JekBox.JekBox.Bot do
  use GenServer
  alias JekBox.Server.Room
  import JekBox.DataMuse.Words

  @default_sleep_seconds 5

  def start_link(room_pid, room, id) do
    GenServer.start_link(__MODULE__, {room_pid, room, id})
  end

  def init({room_pid, room, id}) do
    send(self(), {:register, room, id})
    {:ok, {room_pid, id, "", nil}}
  end

  def handle_info({:register, room, id}, {room_pid, id, "", timer}) do
    name = "🤖 #{JekBox.Server.RoomCodes.new()} BOT"
    {:ok, _state} = JekBox.Server.Room.register_bot(room_pid, id, name)
    JekBoxWeb.Endpoint.subscribe(room)
    log(name, "initialized")
    {:noreply, {room_pid, id, name, timer}}
  end

  def handle_info(
        %{
          payload: %{
            state: %{
              step: :write_clues,
              game_ids: game_ids,
              cur_word: cur_word,
              cur_id: cur_id
            }
          }
        },
        {room_pid, id, name, timer}
      )
      when cur_id != id do
    log(name, "sending clues")
    sleep_seconds(1)
    count = unless map_size(game_ids) == 3, do: 1, else: 2
    Room.clue(room_pid, clues(cur_word, count))
    {:noreply, {room_pid, id, name, timer}}
  end

  def handle_info(
        %{
          payload: %{
            state: %{
              step: :compare_clues,
              leader: id
            }
          }
        },
        {room_pid, id, name, timer}
      ) do
    if timer do
      Process.cancel_timer(timer)
    end

    timer = Process.send_after(self(), :done_clues, 7 * 1000)
    {:noreply, {room_pid, id, name, timer}}
  end

  def handle_info(
        %{
          payload: %{
            state: %{
              step: :guess,
              cur_id: id,
              clues: clues
            }
          }
        },
        {room_pid, id, name, timer}
      ) do
    log(name, "guessing")
    sleep_seconds(1)
    Room.guess(room_pid, guess(clues))
    {:noreply, {room_pid, id, name, timer}}
  end

  def handle_info(
        %{
          payload: %{
            state: %{
              step: :probably_wrong,
              cur_id: id
            }
          }
        },
        {room_pid, id, name, timer}
      ) do
    log(name, "was probably wrong")
    sleep_seconds()
    Room.wrong(room_pid)
    {:noreply, {room_pid, id, name, timer}}
  end

  def handle_info(
        %{
          payload: %{
            state: %{
              step: :actually_wrong,
              cur_id: id
            }
          }
        },
        {room_pid, id, name, timer}
      ) do
    log(name, "was actually wrong")
    sleep_seconds()
    Room.start(room_pid)
    {:noreply, {room_pid, id, name, timer}}
  end

  def handle_info(
        %{
          payload: %{
            state: %{
              step: :pass,
              cur_id: id
            }
          }
        },
        {room_pid, id, name, timer}
      ) do
    log(name, "had to pass")
    sleep_seconds()
    Room.start(room_pid)
    {:noreply, {room_pid, id, name, timer}}
  end

  def handle_info(
        %{
          payload: %{
            state: %{
              step: :right,
              cur_id: id
            }
          }
        },
        {room_pid, id, name, timer}
      ) do
    log(name, "was right")
    sleep_seconds()
    Room.start(room_pid)
    {:noreply, {room_pid, id, name, timer}}
  end

  def handle_info(
        %{
          payload: %{
            state: %{
              step: :end,
              leader: id
            }
          }
        },
        {room_pid, id, name, timer}
      ) do
    log(name, "is leader at end")
    sleep_seconds(7)
    Room.restart(room_pid)
    {:noreply, {room_pid, id, name, timer}}
  end

  def handle_info(:done_clues, {room_pid, id, name, timer}) do
    Room.done_clues(room_pid)
    {:noreply, {room_pid, id, name, timer}}
  end

  def handle_info(event, {room_pid, id, name, timer}) do
    # log(name, "got event STEP [#{event.payload.state.step}]\n#{inspect(event, pretty: true)}")
    {:noreply, {room_pid, id, name, timer}}
  end

  def log(name, message) do
    IO.puts(">>>>>>>> #{name} #{message}")
  end

  def sleep_seconds(sec \\ @default_sleep_seconds) do
    Process.sleep(sec * 1000)
  end
end
