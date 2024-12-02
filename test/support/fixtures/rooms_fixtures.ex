defmodule PlanningPoker.RoomsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PlanningPoker.Rooms` context.
  """

  alias PlanningPoker.Rooms

  @doc """
  Generate a room with default or custom attributes.

  ## Examples:
      # Create room with default attributes
      room_id = room_fixture()

      # Create room with custom mode
      room_id = room_fixture(:fibonacci)
  """
  def room_fixture(mode \\ :mountain_goat) do
    {:ok, room_id} = Rooms.create_room()
    Rooms.set_room_mode(room_id, mode)
    room_id
  end
end
