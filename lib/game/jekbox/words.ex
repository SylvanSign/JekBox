defmodule Game.JekBox.Words do
  def new(num_words \\ 13) do
    file_path()
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.shuffle()
    |> Enum.take(num_words)
  end

  defp file_path do
    Path.join(:code.priv_dir(:game), "nouns.txt")
  end
end
