defmodule PlanningPokerWeb.RoomLive.IndexTest do
  use PlanningPokerWeb.ConnCase
  import Phoenix.LiveViewTest

  describe "Index" do
    test "renders homepage", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "Distributed scrum planning poker"
      assert html =~ "Enter room number"
      assert html =~ "Create new room"
    end

    test "can create a new room", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      {:ok, view, _html} =
        view
        |> element("button", "Create new room")
        |> render_click()
        |> follow_redirect(conn)

      assert view.module == PlanningPokerWeb.RoomLive.Show
    end

    test "can join existing room", %{conn: conn} do
      room_id = PlanningPoker.RoomsFixtures.room_fixture()
      {:ok, view, _html} = live(conn, ~p"/")

      {:ok, view, _html} =
        view
        |> element("form")
        |> render_submit(%{room_number: room_id})
        |> follow_redirect(conn, ~p"/#{room_id}")

      assert view.module == PlanningPokerWeb.RoomLive.Show
    end
  end
end
