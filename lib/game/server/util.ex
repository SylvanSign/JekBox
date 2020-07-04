defmodule Game.Server.Util do
  def transform_room(room) do
    room
    |> String.trim()
    |> String.upcase()
  end
end
