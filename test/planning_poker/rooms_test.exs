defmodule PlanningPoker.RoomsTest do
  use ExUnit.Case, async: false
  alias PlanningPoker.Rooms
  alias PlanningPoker.Rooms.RoomState

  setup do
    # reset the registry before each test
    on_exit(fn ->
      Registry.select(PlanningPoker.Rooms.Registry, [{{:_, :"$1", :_}, [], [:"$1"]}])
      |> Enum.each(fn pid ->
        try do
          GenServer.stop(pid, :normal)
        catch
          _kind, _reason -> :ok
        end
      end)
    end)

    :ok
  end

  describe "create_room/0" do
    test "creates a new room with valid id" do
      assert {:ok, room_id} = Rooms.create_room()
      assert is_binary(room_id)
      assert String.length(room_id) == 6
    end

    test "returns error when room limit is reached" do
      original_max_rooms = Application.get_env(:planning_poker, :max_rooms)
      Application.put_env(:planning_poker, :max_rooms, 1)
      on_exit(fn -> Application.put_env(:planning_poker, :max_rooms, original_max_rooms) end)

      assert {:ok, _room_id} = Rooms.create_room()
      assert {:error, :room_limit_reached} = Rooms.create_room()
    end
  end

  describe "get_room_state/1" do
    test "returns room state for existing room" do
      {:ok, room_id} = Rooms.create_room()
      assert {:ok, %RoomState{id: ^room_id, mode: :mountain_goat}} = Rooms.get_room_state(room_id)
    end

    test "returns error for non-existing room" do
      assert {:error, :room_not_found} = Rooms.get_room_state("000000")
    end
  end

  describe "set_room_mode/2" do
    test "updates room mode" do
      {:ok, room_id} = Rooms.create_room()
      assert :ok = Rooms.set_room_mode(room_id, :fibonacci)
      assert {:ok, %RoomState{mode: :fibonacci}} = Rooms.get_room_state(room_id)
    end
  end
end
