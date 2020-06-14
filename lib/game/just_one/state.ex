defmodule Game.JustOne.State do
  @steps [:write_clues, :compare_clues, :guess, :check_end]

  def new(players) do
    players = Enum.shuffle(players)
    words = Game.JustOne.Words.new()

    %{
      players: players,
      words: words,
      steps: @steps
    }
  end

  def act(%{steps: [:write_clues | ss], players: [cp | ps]} = state, p, action) when cp != p do
    IO.puts("nice")
  end

  def act(_state, _player, _action) do
    IO.puts("YIKERS")
  end
end
