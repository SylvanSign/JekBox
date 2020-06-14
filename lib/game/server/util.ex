defmodule Game.Util do
  def transform_room(room) do
    room
    |> String.upcase()
    |> String.to_atom()
  end
end
