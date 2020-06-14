defmodule Game.JustOne.State do
  alias Game.JustOne

  @steps [:write_clues, :compare_clues, :guess, :check_end]

  def new(room) do
    %{
      room: room,
      step: :lobby,
      pids: Map.new(),
      pid_list: [],
      cur_seat: 0,
      cur_word: nil,
      words: JustOne.Words.new(),
      broadcast: true,
      clues: %{},
      pending_clues: 0
    }
  end

  def start(state) do
    %{state | step: :game}
    |> write_clues()
  end

  def write_clues(state) do
    clues = clues(state)

    %{
      state
      | step: :write_clues,
        broadcast: true,
        clues: clues,
        pending_clues: map_size(clues)
    }
  end

  def clues(%{pid_list: pid_list, cur_seat: cur_seat} = state) do
    pid_list
    |> List.delete_at(cur_seat)
    |> Enum.map(&elem(&1, 0))
    |> Enum.into(%{}, &{&1, ""})
  end

  def clue(%{clues: clues, pending_clues: pending_clues} = state, pid, clue) do
    clues = Map.put(clues, pid, clue)
    pending_clues = pending_clues - 1

    state = %{
      state
      | clues: clues,
        pending_clues: pending_clues
    }

    unless pending_clues == 0 do
      state
    else
      %{
        state
        | step: :compare_clues
      }
    end
  end

  def next_step([]) do
    @steps
  end

  def register_pid(%{pids: pids} = state, pid, name) do
    %{
      state
      | pids: Map.put(pids, pid, name)
    }
    |> fix_state()
  end

  def forget_pid(%{pids: pids} = state, pid) do
    %{state | pids: Map.delete(pids, pid)}
    |> fix_state()
  end

  def act(%{steps: [:write_clues | ss], players: [cp | ps]} = state, p, action) when cp != p do
    IO.puts("nice")
  end

  def act(_state, _player, _action) do
    IO.puts("YIKERS")
  end

  def fix_state(
        %{
          pids: pids
        } = state
      ) do
    %{
      state
      | broadcast: true,
        pid_list:
          pids
          |> Enum.sort(fn {_, a_name}, {_, b_name} ->
            a_name < b_name
          end)
    }
  end
end
