defmodule Game.JekBox.Bot do
  use GenServer
  alias Game.Server.Room

  def start_link(room_pid, room, id) do
    GenServer.start_link(__MODULE__, {room_pid, room, id})
  end

  def init({room_pid, room, id}) do
    send(self(), {:register, room, id})
    {:ok, {room_pid, id, ""}}
  end

  def handle_info({:register, room, id}, {room_pid, id, ""}) do
    name = "#{Game.Server.RoomCodes.new()} BOT"
    {:ok, _state} = Game.Server.Room.register_bot(room_pid, id, name)
    GameWeb.Endpoint.subscribe(room)
    log(name, "initialized")
    {:noreply, {room_pid, id, name}}
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
        {room_pid, id, name}
      )
      when cur_id != id do
    log(name, "sending clues")
    sleep_seconds()
    count = unless map_size(game_ids) == 3, do: 1, else: 2
    Room.clue(room_pid, clues(cur_word, count))
    {:noreply, {room_pid, id, name}}
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
        {room_pid, id, name}
      ) do
    log(name, "done comparing clues")
    sleep_seconds()
    Room.done_clues(room_pid)
    {:noreply, {room_pid, id, name}}
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
        {room_pid, id, name}
      ) do
    log(name, "guessing")
    sleep_seconds()
    Room.guess(room_pid, guess(clues))
    {:noreply, {room_pid, id, name}}
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
        {room_pid, id, name}
      ) do
    log(name, "was probably wrong")
    sleep_seconds()
    Room.wrong(room_pid)
    {:noreply, {room_pid, id, name}}
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
        {room_pid, id, name}
      ) do
    log(name, "was probably wrong")
    sleep_seconds()
    Room.wrong(room_pid)
    {:noreply, {room_pid, id, name}}
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
        {room_pid, id, name}
      ) do
    log(name, "was actually wrong")
    sleep_seconds()
    Room.start(room_pid)
    {:noreply, {room_pid, id, name}}
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
        {room_pid, id, name}
      ) do
    log(name, "had to pass")
    sleep_seconds()
    Room.start(room_pid)
    {:noreply, {room_pid, id, name}}
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
        {room_pid, id, name}
      ) do
    log(name, "was right")
    sleep_seconds()
    Room.start(room_pid)
    {:noreply, {room_pid, id, name}}
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
        {room_pid, id, name}
      ) do
    log(name, "is leader at end")
    sleep_seconds()
    Room.restart(room_pid)
    {:noreply, {room_pid, id, name}}
  end

  def handle_info(event, {room_pid, id, name}) do
    log(name, "got event STEP [#{event.payload.state.step}]\n#{inspect(event)}")
    {:noreply, {room_pid, id, name}}
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
    IO.puts(">>>>>>>> #{name} - #{message}")
  end

  def sleep_seconds(sec \\ 5) do
    Process.sleep(sec * 1000)
  end
end
