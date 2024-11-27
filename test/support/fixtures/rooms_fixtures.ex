defmodule PlanningPoker.RoomsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PlanningPoker.Rooms` context.
  """

  alias PlanningPoker.Rooms.Server

  @doc """
  Generate a room with default or custom attributes.

  ## Examples:
      # Create room with default attributes
      room_id = room_fixture()

      # Create room with custom mode
      room_id = room_fixture(:fibonacci)
  """
  def room_fixture(mode \\ :mountain_goat) do
    {:ok, room_id} = Server.create_room()
    Server.set_mode(room_id, mode)
    room_id
  end

  @doc """
  Generate a room and return its full state.

  ## Examples:
      # Get room state with default attributes
      room_state = room_state_fixture()

      # Get room state with custom mode
      room_state = room_state_fixture(:fibonacci)
  """
  def room_state_fixture(mode \\ :mountain_goat) do
    room_id = room_fixture(mode)
    {:ok, state} = Server.get_state(room_id)
    state
  end
end
