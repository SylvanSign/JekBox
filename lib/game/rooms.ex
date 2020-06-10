defmodule GameWeb.Rooms do
  use GenServer

  @chars String.codepoints("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
  @length_of_room_name 4

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
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
    name = generate_new_name()
    {:reply, name, Map.put(rooms, name, [from_pid])}
  end

  @impl true
  def handle_call(:state, _from, rooms) do
    {:reply, rooms, rooms}
  end

  defp generate_new_name() do
    Enum.reduce(1..@length_of_room_name, [], fn _i, acc ->
      [Enum.random(@chars) | acc]
    end)
    |> Enum.join("")
  end

  defp get_unique_name_helper(rooms, name \\ generate_new_name(), tries \\ 0) do
    unless Map.has_key?(rooms, name) do
      {:ok, name}
    else
      if tries > 1000 do
        {:error}
      else
        get_unique_name_helper(rooms, generate_new_name(), tries + 1)
      end
    end
  end
end
