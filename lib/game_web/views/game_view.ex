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

  def score_message(13), do: "Perfect score! Can you do it again?"
  def score_message(12), do: "Incredible! Your friends must be impressed!"
  def score_message(11), do: "Awesome! That's a score worth celebrating!"
  def score_message(score) when score in 9..10, do: "Wow, not bad at all!"
  def score_message(score) when score in 7..8, do: "You're in the average. Can you do better?"
  def score_message(score) when score in 4..6, do: "That's a good start. Try again!"
  def score_message(score) when score in 0..3, do: "Try again, and again, and again."
end
