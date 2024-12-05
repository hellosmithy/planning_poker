defmodule PlanningPoker.RoomsTest do
  use ExUnit.Case, async: false
  use Mimic

  alias PlanningPoker.Rooms
  alias PlanningPoker.Rooms.Server
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
      Server
      |> stub(:max_rooms, fn -> 1 end)

      assert {:ok, _room_id} = Rooms.create_room()
      assert {:error, :room_limit_reached} = Rooms.create_room()
    end

    test "retries 5 times generating room id when collision occurs" do
      Server
      |> expect(:generate_room_id, 5, fn -> "111111" end)
      |> expect(:generate_room_id, 1, fn -> "222222" end)

      assert {:ok, "111111"} = Rooms.create_room()
      assert {:ok, "222222"} = Rooms.create_room()

      verify!()
    end

    test "returns error when room id collision occurs more than 5 times" do
      Server
      |> expect(:generate_room_id, 6, fn -> "333333" end)

      assert {:ok, "333333"} = Rooms.create_room()
      assert {:error, :room_id_collision} = Rooms.create_room()

      verify!()
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
