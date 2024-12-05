defmodule PlanningPoker.E2E.RoomsTest do
  use ExUnit.Case, async: false
  use Wallaby.Feature

  import PlanningPoker.E2E.Fixtures

  feature "creating a new room", %{session: session} do
    # Creating a new room should redirect to the room page
    session
    |> visit("/")
    |> click(Query.button("Create new room"))

    assert_has(session, Query.css("h2", text: "Room "))
    assert current_path(session) =~ ~r/\/\d{6}$/
  end

  feature "joining a room", %{session: session} do
    {session, room_number} = create_room(session)

    # Join the newly created room
    session
    |> visit("/")
    |> fill_in(Query.css("#room_number"), with: room_number)
    |> click(Query.button("Join room"))

    assert_has(session, Query.css("h2", text: "Room #{room_number}"))

    # Joining a non-existent room should redirect to the home page and show a flash message
    session
    |> visit("/")
    |> fill_in(Query.css("#room_number"), with: "123456")
    |> click(Query.button("Join room"))

    assert current_path(session) == "/"
    assert_has(session, Query.css("#flash-error", text: "Room not found!"))
  end
end
