defmodule PlanningPoker.Rooms.ServerTest do
  use ExUnit.Case, async: false
  alias PlanningPoker.Rooms.Server
  alias PlanningPoker.Rooms.RoomState
  alias PlanningPoker.RoomsFixtures

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

  describe "get_state/1" do
    setup do
      {:ok, room_id: RoomsFixtures.room_fixture()}
    end

    test "returns room state for a given room id", %{room_id: room_id} do
      assert %RoomState{id: ^room_id, mode: :mountain_goat} = Server.get_state(room_id)
    end
  end

  describe "update_state/2" do
    setup do
      {:ok, room_id: RoomsFixtures.room_fixture()}
    end

    test "updates room state", %{room_id: room_id} do
      Server.update_state(room_id, %{mode: :fibonacci})
      assert %RoomState{id: ^room_id, mode: :fibonacci} = Server.get_state(room_id)
    end
  end

  describe "room lifecycle" do
    setup do
      {:ok, room_id: RoomsFixtures.room_fixture()}
    end

    test "room terminates after idle timeout", %{room_id: room_id} do
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
