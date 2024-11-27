defmodule PlanningPoker.Rooms.ServerTest do
  use ExUnit.Case, async: false
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
      assert {:ok, room_id} = Server.create_room()
      assert is_binary(room_id)
      assert String.length(room_id) == 6
    end

    test "returns error when room limit is reached" do
      original = Application.get_env(:planning_poker, :max_rooms)
      Application.put_env(:planning_poker, :max_rooms, 2)
      on_exit(fn -> Application.put_env(:planning_poker, :max_rooms, original) end)

      {:ok, _} = Server.create_room()
      {:ok, _} = Server.create_room()
      assert {:error, :room_limit_reached} = Server.create_room()
    end
  end

  describe "get_state/1" do
    test "returns room state for existing room" do
      {:ok, room_id} = Server.create_room()
      assert %RoomState{id: ^room_id, mode: :mountain_goat} = Server.get_state(room_id)
    end

    test "returns error for non-existing room" do
      assert {:error, :room_not_found} = Server.get_state("000000")
    end
  end

  describe "mode operations" do
    setup do
      {:ok, room_id} = Server.create_room()
      {:ok, room_id: room_id}
    end

    test "set_mode/2 updates room mode", %{room_id: room_id} do
      Server.set_mode(room_id, :fibonacci)
      assert :fibonacci = Server.get_mode(room_id)
    end

    test "get_mode/1 returns current mode", %{room_id: room_id} do
      assert :mountain_goat = Server.get_mode(room_id)
    end
  end

  describe "room lifecycle" do
    test "room terminates after idle timeout" do
      {:ok, room_id} = Server.create_room()

      # Get the PID of the room server
      [{pid, _}] = Registry.lookup(PlanningPoker.Rooms.Registry, room_id)

      # Monitor the process
      ref = Process.monitor(pid)

      # Force timeout
      send(pid, :timeout)

      # Assert that the process dies
      assert_receive {:DOWN, ^ref, :process, ^pid, :normal}

      # Verify process is not alive
      refute Process.alive?(pid)
    end
  end
end
