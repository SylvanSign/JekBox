defmodule Game.Rooms do
  use GenServer

  @chars String.codepoints("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
  @length_of_room_name 4

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def state do
    GenServer.call(__MODULE__, :state)
  end

  def new do
    GenServer.call(__MODULE__, :new)
  end

  @impl true
  def init([]) do
    {:ok, %{}}
  end

  @impl true
  def handle_call(:new, {from_pid, _ref}, rooms) do
    {:ok, name} = get_unique_room_name(rooms)
    {:reply, name, Map.put(rooms, name, [from_pid])}
  end

  @impl true
  def handle_call(:state, _from, rooms) do
    {:reply, rooms, rooms}
  end

  defp get_unique_room_name(rooms, name \\ generate_new_name(), tries \\ 0) do
    unless Map.has_key?(rooms, name) do
      {:ok, name}
    else
      if tries > 1000 do
        {:error}
      else
        get_unique_room_name(rooms, generate_new_name(), tries + 1)
      end
    end
  end

  defp generate_new_name() do
    Enum.reduce(1..@length_of_room_name, [], fn _i, acc ->
      [Enum.random(@chars) | acc]
    end)
    |> Enum.join("")
  end
end
