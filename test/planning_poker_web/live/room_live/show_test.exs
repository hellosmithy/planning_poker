defmodule PlanningPokerWeb.RoomLive.ShowTest do
  use PlanningPokerWeb.ConnCase
  import Phoenix.LiveViewTest
  import PlanningPoker.RoomsFixtures

  describe "Show" do
    test "renders room with default mode", %{conn: conn} do
      room_id = room_fixture()
      {:ok, _view, html} = live(conn, ~p"/#{room_id}")

      assert html =~ "Room #{room_id}"
      assert html =~ "Mode: mountain_goat"
    end

    test "can change room mode", %{conn: conn} do
      room_id = room_fixture()
      {:ok, view, _html} = live(conn, ~p"/#{room_id}")

      assert view
             |> element("form")
             |> render_change(%{"room" => %{"id" => room_id, "mode" => "fibonacci"}}) =~
               "Mode: fibonacci"

      # Verify the state was actually updated
      assert {:ok, updated_state} = PlanningPoker.Rooms.get_room_state(room_id)
      assert updated_state.mode == :fibonacci
    end

    test "redirects when room not found", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/", flash: %{"error" => "Room not found!"}}}} =
               live(conn, ~p"/invalid-room")
    end
  end
end
