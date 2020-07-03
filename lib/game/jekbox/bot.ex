defmodule Game.JekBox.Bot do
  use GenServer
  alias Game.Server.Room

  @default_sleep_seconds 3

  def start_link(room_pid, room, id) do
    GenServer.start_link(__MODULE__, {room_pid, room, id})
  end

  def init({room_pid, room, id}) do
    send(self(), {:register, room, id})
    {:ok, {room_pid, id, "", nil}}
  end

  def handle_info({:register, room, id}, {room_pid, id, "", timer}) do
    name = "🤖 #{Game.Server.RoomCodes.new()} BOT"
    {:ok, _state} = Game.Server.Room.register_bot(room_pid, id, name)
    GameWeb.Endpoint.subscribe(room)
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
    sleep_seconds()
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

    timer = Process.send_after(self(), :done_clues, 5 * 1000)
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
    sleep_seconds()
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
    sleep_seconds()
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

  def clues(word, count \\ 1) do
    results = means_like(word)

    results
    |> Enum.take(div(length(results), 3))
    |> Enum.shuffle()
    |> Enum.take(count)
    |> Enum.map(&(&1 |> Map.get("word") |> String.upcase()))
  end

  def guess(words) do
    words
    |> Enum.join(",")
    |> means_like()
    |> hd()
    |> Map.get("word")
    |> String.upcase()
  end

  def means_like(input) do
    {:ok, {_, _, raw}} = :httpc.request('https://api.datamuse.com/words?ml=#{input}')

    Jason.decode!(raw)
  end

  def log(name, message) do
    IO.puts(">>>>>>>> #{name} #{message}")
  end

  def sleep_seconds(sec \\ @default_sleep_seconds) do
    Process.sleep(sec * 1000)
  end
end
