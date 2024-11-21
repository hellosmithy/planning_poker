defmodule PlanningPokerWeb.RoomLive.Index do
  use PlanningPokerWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h2>Distributed scrum planning poker for estimating agile projects.</h2>
    <p>
      First person to create the room is the moderator. Share the url or room number with other team members to join the room.
    </p>

    <div class="flex flex-col items-center space-y-4">
      <form phx-submit="join_room" class="space-y-4">
        <div>
          <label for="room_number">Enter room number</label>
          <input id="room_number" name="room_number" placeholder="room no" />
        </div>
        <button type="submit">Join Room</button>
      </form>
    </div>
    """
  end

  @impl true
  def handle_event("join_room", %{"room_number" => room_number}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/#{room_number}")}
  end
end
