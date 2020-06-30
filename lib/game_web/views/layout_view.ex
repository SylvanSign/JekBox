defmodule GameWeb.LayoutView do
  use GameWeb, :view

  def debug(assigns) do
    ~L"""
    <%= if true do %>
    <pre>
    <%= assigns |> Enum.map(fn {k, v} -> "#{k}: #{inspect(v)}" end) |> Enum.join("\n") %>
    ======
    <%= @state |> Enum.map(fn {k, v} -> "#{k}: #{inspect(v)}" end) |> Enum.join("\n") %>
    </pre>
    <% end %>
    """
  end
end
