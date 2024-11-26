defmodule PlanningPoker.Rooms do
  @moduledoc """
  The Rooms context.
  """

  alias PlanningPoker.Rooms.Server
  alias PlanningPoker.Rooms.Room

  def create_room(), do: Server.create_room()

  def get_room_state(room_id) do
    case Server.get_state(room_id) do
      %Room{} = room -> {:ok, room}
      _ -> {:error, :room_not_found}
    end
  end

  def set_room_mode(room_id, mode), do: Server.set_mode(room_id, mode)
end
