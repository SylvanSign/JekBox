defmodule Game.JekBox.Bot do
  use GenServer
  alias Game.Server.Room

  def start_link(room_pid, room, id) do
    GenServer.start_link(__MODULE__, {room_pid, room, id})
  end

  def init({room_pid, room, id}) do
    send(self(), {:register, room, id})
    {:ok, {room_pid, nil}}
  end

  def handle_info({:register, room, id}, {room_pid, timer}) do
    name = "#{Game.Server.RoomCodes.new()} BOT"
    {:ok, _state} = Game.Server.Room.register_bot(room_pid, id, name)
    GameWeb.Endpoint.subscribe(room)
    IO.puts(">>>>>>>> initialized #{name}")
    {:noreply, {room_pid, timer}}
  end

  def handle_info(
        %{
          event: "state",
          payload: %{
            state: %{
              step: :write_clues,
              game_ids: game_ids,
              cur_word: cur_word
            }
          }
        },
        {room_pid, timer}
      ) do
    IO.puts(">>>>>>>> BOT ABOUT TO SEND CLUES")
    Process.sleep(:rand.uniform(5000) + 1000)
    count = unless map_size(game_ids) == 3, do: 1, else: 2
    Room.clue(room_pid, clues(cur_word, count))
    {:noreply, {room_pid, timer}}
  end

  def handle_info(
        %{
          event: "state",
          payload: %{
            state: %{
              step: :compare_clues
            }
          }
        },
        {room_pid, _timer}
      ) do
    IO.puts(">>>>>>>> BOT ABOUT TO DONE_CLUES")

    timer = Process.send_after(self(), :done_clues, :rand.uniform(5000) + 3000)
    {:noreply, {room_pid, timer}}
  end

  def handle_info(
        %{
          event: "state",
          payload: %{
            state: %{
              step: :guess
            }
          }
        },
        {room_pid, timer}
      ) do
    IO.puts(">>>>>>>> BOT ABOUT TO GUESS")
    timer = Process.cancel_timer(timer)

    {:noreply, {room_pid, timer}}
  end

  def handle_info(:done_clues, {room_pid, timer}) do
    Room.done_clues(room_pid)
    {:noreply, {room_pid, timer}}
  end

  def handle_info(event, {room_pid, timer}) do
    IO.puts(">>>>>>>> BOT GOT EVENT #{inspect(event)}")
    {:noreply, {room_pid, timer}}
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
end
