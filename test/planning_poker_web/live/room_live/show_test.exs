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
      topic = "room:#{room_id}"
      Phoenix.PubSub.subscribe(PlanningPoker.PubSub, topic)

      {:ok, view, _html} = live(conn, ~p"/#{room_id}")

      # First assert the initial state
      assert render(view) =~ "Mode: mountain_goat"

      # Perform the change
      view
      |> element("form")
      |> render_change(%{"room" => %{"mode" => "fibonacci"}})

      # Wait for the broadcast to be processed
      assert_receive {:room_state, %{mode: :fibonacci}, :set_room_mode}

      # Now check the updated content
      assert render(view) =~ "Mode: fibonacci"
    end

    test "redirects when room not found", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/", flash: %{"error" => "Room not found!"}}}} =
               live(conn, ~p"/invalid-room")
    end
  end
end
