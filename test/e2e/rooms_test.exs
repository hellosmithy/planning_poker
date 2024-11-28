defmodule PlanningPoker.E2E.RoomsTest do
  use ExUnit.Case, async: true
  use Wallaby.Feature

  feature "creating a new room", %{session: session} do
    # Visit the home page and click the "Create new room" button
    session
    |> visit("/")
    |> click(Query.button("Create new room"))

    # Assert we're on a room page with a 6-digit room number
    assert_has(session, Query.css("h2", text: "Room "))
    assert current_path(session) =~ ~r/\/\d{6}$/
  end
end
