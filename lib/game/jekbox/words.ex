defmodule Game.JekBox.Words do
  use Agent

  def start_link(opts) do
    Agent.start_link(fn -> new() end, opts)
  end

  def word do
    Agent.get(__MODULE__, &Enum.random(&1))
  end

  defp new do
    file_path()
    |> File.read!()
    |> String.split("\n", trim: true)
  end

  defp file_path do
    Path.join(:code.priv_dir(:game), "nouns.txt")
  end
end
