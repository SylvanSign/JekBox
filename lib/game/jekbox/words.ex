defmodule Game.JekBox.Words do
  use Agent

  @words Path.join(:code.priv_dir(:game), "nouns.txt")
         |> File.read!()
         |> String.split("\n", trim: true)

  def start_link(opts) do
    Agent.start_link(fn -> Enum.shuffle(@words) end, opts)
  end

  def word do
    Agent.get_and_update(__MODULE__, fn words ->
      [w | ws] =
        case words do
          [] ->
            Enum.shuffle(@words)

          words ->
            words
        end

      {w, ws}
    end)
  end
end
