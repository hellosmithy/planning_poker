defmodule PlanningPoker.Rooms.RoomStateTest do
  use ExUnit.Case, async: true
  alias PlanningPoker.Rooms.RoomState

  describe "new/1" do
    test "creates a new room with default mode" do
      room = RoomState.new(123)
      assert room.id == 123
      assert room.mode == :mountain_goat
    end
  end

  describe "set_mode/2" do
    test "updates room mode when given valid mode" do
      room = RoomState.new(123)
      updated_room = RoomState.set_mode(room, :fibonacci)
      assert updated_room.mode == :fibonacci
      assert updated_room.id == 123
    end
  end

  describe "valid_mode?/1" do
    test "returns true for valid modes" do
      valid_modes = [:mountain_goat, :fibonacci, :sequential, :playing_cards, :t_shirt_sizes]

      for mode <- valid_modes do
        assert RoomState.valid_mode?(mode)
      end
    end

    test "returns false for invalid modes" do
      assert not RoomState.valid_mode?(:invalid_mode)
      assert not RoomState.valid_mode?(:other)
    end
  end
end
