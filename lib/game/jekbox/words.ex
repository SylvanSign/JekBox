defmodule JekBox.JekBox.Words do
  use Agent

  def start_link(opts) do
    Agent.start_link(fn -> fresh_words() end, opts)
  end

  def word do
    Agent.get_and_update(__MODULE__, fn words ->
      [w | ws] =
        case words do
          [] ->
            fresh_words()

          words ->
            words
        end

      {w, ws}
    end)
  end

  defp fresh_words do
    Path.join(:code.priv_dir(:jek_box), "nouns.txt")
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.shuffle()
  end
end
