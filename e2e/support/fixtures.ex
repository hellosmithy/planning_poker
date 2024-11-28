defmodule PlanningPoker.E2E.Fixtures do
  import Wallaby.Browser

  alias Wallaby.Query
  alias Wallaby.Element

  def create_room(session) do
    session =
      session
      |> visit("/")
      |> click(Query.button("Create new room"))
      |> assert_has(Query.css("[data-room-id]"))

    room_number =
      session
      |> find(Query.css("[data-room-id]"))
      |> Element.attr("data-room-id")

    {session, room_number}
  end
end
