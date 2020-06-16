defmodule GameWeb.GameView do
  use GameWeb, :view

  def preamble(assigns) do
    ~L"""
    <%= if @state.step != :lobby and @state.step != :end do %>
      <h1>On Word <%= @state.word_count - length(@state.words) %> of <%= @state.word_count %></h1>
      <%= if guesser?(assigns) do %>
        <h2>You are the <%= bold("Guesser") %></h2>
      <% else %>
        <h2>You are a <%= bold("Clue Giver") %> for <%= tag_guesser(@state.guesser_name) %></h2>
      <% end %>
    <% end %>
    """
  end

  def guesser?(assigns) do
    assigns.state.cur_pid == self()
  end

  def bold(word) do
    ~e"""
    <strong><%= word %></strong>
    """
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
