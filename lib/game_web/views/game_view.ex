defmodule GameWeb.GameView do
  use GameWeb, :view

  def preamble(assigns) do
    ~L"""
    <%= if @state.step != :lobby and @state.step != :end do %>
      <h2><%= lives(assigns) %></h2>
      <h2><%= score(assigns) %> · <%= top_score(assigns) %></h2>
      <%= if guesser?(assigns) do %>
        <h2><%= bold("Guesser") %></h2>
      <% else %>
        <h2><%= bold("Clue Giver") %> for <%= tag_guesser(@state.guesser_name) %></h2>
      <% end %>
    <% end %>
    """
  end

  def score(assigns) do
    score = length(assigns.state.scored)

    color =
      if score > assigns.state.record do
        :green
      else
        :black
      end

    ~L"""
    Score <%= bold(length(@state.scored), color) %>
    """
  end

  def top_score(assigns) do
    score = length(assigns.state.scored)

    ~L"""
    Best <%= bold(max(@state.record, score)) %>
    """
  end

  def lives(assigns) do
    lost = length(assigns.state.lost)
    lives = assigns.state.lives
    lives_left = lives - lost

    hearts = String.duplicate("❤️", lives_left)
    xs = String.duplicate("💔", lost)

    ~L"""
    <%= hearts <> xs %>
    """
  end

  def continue_button(assigns, id \\ "") do
    button_text =
      unless length(assigns.state.lost) == assigns.state.lives do
        "NEXT ROUND"
      else
        "SEE FINAL SCORE"
      end

    ~L"""
    <button phx-click="start" id="<%= id %>"><%= button_text %></button>
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
