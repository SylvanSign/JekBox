defmodule GameWeb.LayoutView do
  use GameWeb, :view

  def debug(assigns) do
    ~L"""
    <%= if false do %>
    <pre>
    <%= @state |> Enum.map(fn {k, v} -> "#{k}: #{inspect(v)}" end) |> Enum.join("\n") %>
    </pre>
    <% end %>
    """
  end
end
