defmodule Game.JustOne.State do
  alias Game.JustOne

  def new(room, word_count \\ 13) do
    %{
      room: room,
      step: :lobby,
      ids: Map.new(),
      id_list: [],
      cur_id: nil,
      cur_seat: -1,
      cur_word: nil,
      cur_guess: nil,
      guesser_name: nil,
      words: JustOne.Words.new(word_count),
      word_count: word_count,
      broadcast: true,
      clues: %{},
      dups: [],
      pending_clues: 0,
      scored: [],
      lost: []
    }
  end

  def start(state) do
    state
    |> continue_or_end()
  end

  def write_clues(
        %{
          id_list: id_list,
          cur_seat: cur_seat,
          words: [word | words]
        } = state
      ) do
    clues =
      id_list
      |> List.delete_at(cur_seat)
      |> Enum.map(&elem(&1, 0))
      |> Enum.into(%{}, &{&1, ""})

    {cur_id, guesser_name} = id_list |> Enum.at(cur_seat)

    %{
      state
      | step: :write_clues,
        broadcast: true,
        clues: clues,
        cur_id: cur_id,
        guesser_name: guesser_name,
        cur_word: word,
        words: words,
        pending_clues: map_size(clues)
    }
  end

  def clue(%{clues: clues, pending_clues: pending_clues} = state, id, clue) do
    clues = Map.put(clues, id, clue)
    pending_clues = pending_clues - 1

    state = %{
      state
      | clues: clues,
        pending_clues: pending_clues
    }

    unless pending_clues == 0 do
      state
    else
      {clues, dups} = prep_for_clue_comparison(clues)

      %{
        state
        | step: :compare_clues,
          clues: clues,
          dups: dups
      }
    end
  end

  def toggle_duplicate(%{clues: clues} = state, clue) do
    %{
      state
      | clues: Map.update!(clues, clue, &(not &1))
    }
  end

  def done_clues(%{clues: clues} = state) do
    %{
      state
      | clues:
          clues
          |> Enum.reject(&elem(&1, 1))
          |> Enum.map(&elem(&1, 0)),
        step: :guess
    }
  end

  def continue_or_end(%{words: words, cur_seat: cur_seat, id_list: id_list} = state) do
    if Enum.empty?(words) do
      %{
        state
        | step: :end
      }
    else
      %{
        state
        | cur_seat: next_seat(cur_seat, id_list)
      }
      |> write_clues()
    end
  end

  def next_seat(cur_seat, id_list) do
    rem(cur_seat + 1, length(id_list))
  end

  def pass(%{lost: lost, cur_word: cur_word} = state) do
    %{
      state
      | lost: [cur_word | lost],
        step: :pass
    }
  end

  def guess(%{cur_word: guess, scored: scored} = state, guess) do
    %{
      state
      | scored: [guess | scored],
        step: :right
    }
  end

  def guess(state, guess) do
    %{
      state
      | step: :check_guess,
        cur_guess: guess
    }
  end

  def correct(%{cur_word: cur_word} = state) do
    # Pretend we guessed correctly
    guess(state, cur_word)
  end

  def incorrect(%{cur_word: cur_word, lost: lost, words: [next_word | words]} = state) do
    %{
      state
      | lost: [next_word, cur_word | lost],
        words: words,
        step: :wrong
    }
  end

  def incorrect(%{cur_word: cur_word, lost: lost, words: []} = state) do
    %{
      state
      | lost: [cur_word | lost]
    }
  end

  def register_id(%{ids: ids} = state, id, name) do
    %{
      state
      | ids: Map.put(ids, id, name)
    }
    |> fix_state()
  end

  def forget_id(%{ids: ids} = state, id) do
    %{state | ids: Map.delete(ids, id)}
    |> fix_state()
  end

  def fix_state(
        %{
          ids: ids
        } = state
      ) do
    %{
      state
      | broadcast: true,
        id_list:
          ids
          |> Enum.sort(fn {_, a_name}, {_, b_name} ->
            a_name < b_name
          end)
    }
  end

  def prep_for_clue_comparison(clues) do
    {clues, dups} =
      clues
      |> Enum.map(&elem(&1, 1))
      |> Enum.reduce({%{}, %{}}, fn clue, {all, dups} ->
        if Map.has_key?(all, clue) do
          {all, Map.update(dups, clue, 2, &(&1 + 1))}
        else
          {Map.put(all, clue, false), dups}
        end
      end)

    clues =
      clues
      |> Enum.reject(&Map.has_key?(dups, elem(&1, 0)))
      |> Enum.into(%{})

    dups =
      dups
      |> Enum.map(fn {dup, times} ->
        List.duplicate(dup, times)
      end)
      |> Enum.concat()

    {clues, dups}
  end
end
