defmodule GameWeb.GameView do
  use GameWeb, :view

  def preamble(assigns) do
    ~L"""
    <%= if @state.step != :lobby and @state.step != :end do %>
      <h2><%= score(assigns) %> · <%= strikes(assigns) %></h2>
      <hr>
      <%= if guesser?(assigns) do %>
        <h2><%= bold("Guesser") %></h2>
      <% else %>
        <h2><%= bold("Clue Giver") %> for <%= tag_guesser(@state.guesser_name) %></h2>
      <% end %>
    <% end %>
    <hr>
    """
  end

  def score(assigns) do
    ~L"""
    Score: <%= bold(length(@state.scored), :green) %>
    """
  end

  def strikes(assigns) do
    lost = length(assigns.state.lost)
    strikes = assigns.state.strikes

    color =
      case lost do
        0 -> :green
        _ -> :red
      end

    ~L"""
    Strikes: <%= bold(lost, color) %> <%= bold("/ #{strikes}") %>
    """
  end

  def guesser?(assigns) do
    assigns.state.cur_id == assigns.id
  end

  def clues(assigns, clickable? \\ false) do
    ~L"""
    <%= for dup <- @state.dups do %>
      <button class="button-outline"><%= dup %></button>
    <% end %>
    <%= if clickable? do %>
      <%= for {clue, selected} <- @state.clues do %>
        <% class = unless selected, do: "button-clear", else: "button-outline" %>
        <button class="<%= class %>" phx-click="toggle_duplicate" phx-value-clue="<%= clue %>"><%= clue %></button>
      <% end %>
    <% else %>
      <%= for clue <- @state.clues do %>
        <button class="button-clear"><%= clue %></button>
      <% end %>
    <% end %>
    """
  end

  def bold(word, color \\ nil) do
    case color do
      nil ->
        ~e"""
        <strong><%= word %></strong>
        """

      _ ->
        ~e"""
        <strong style="color: <%= color %>;"><%= word %></strong>
        """
    end
  end

  def tag_guesser(name) do
    ~e"""
    <em><%= name %></em>
    """
  end

  def present_word(word) do
    ~e"""
    <blockquote>
      <%= bold(word) %>
    </blockquote>
    """
  end
end
