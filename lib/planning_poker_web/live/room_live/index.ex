defmodule PlanningPokerWeb.RoomLive.Index do
  alias PlanningPoker.Rooms
  use PlanningPokerWeb, :live_view

  ###
  ### Lifecycle
  ###

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h2 class="mb-4 text-2xl font-bold leading-none tracking-tight text-gray-900 dark:text-white sm:px-16 md:text-3xl lg:text-4xl">
      Distributed scrum planning poker for estimating agile projects.
    </h2>
    <p class="mb-8 text-lg font-normal text-gray-500 dark:text-gray-400 sm:px-16 lg:text-xl">
      First person to create the room is the moderator. Share the url or room number with other team members to join the room.
    </p>

    <div class="flex flex-col space-y-4 sm:px-16">
      <form
        phx-submit="join_room"
        class="mx-aut mb-3 flex w-full max-w-sm max-w-md items-center space-x-4"
      >
        <div class="mb-5">
          <label
            for="room_number"
            class="mb-2 block text-sm font-medium text-gray-900 dark:text-white"
          >
            Enter room number
          </label>
          <input
            type="text"
            id="room_number"
            name="room_number"
            placeholder="e.g. 123456"
            class="block w-full rounded-lg border border-gray-300 bg-gray-50 p-3.5 text-base text-gray-900 focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white dark:placeholder-gray-400 dark:focus:border-blue-500 dark:focus:ring-blue-500"
          />
        </div>

        <button
          type="submit"
          class="me-2 mt-4 mb-2 inline-flex items-center rounded-lg border border-gray-800 px-6 py-4 text-center text-sm font-medium text-gray-900 hover:bg-gray-900 hover:text-white focus:outline-none focus:ring-4 focus:ring-gray-300 dark:border-gray-600 dark:text-gray-400 dark:hover:bg-gray-600 dark:hover:text-white dark:focus:ring-gray-800"
        >
          Join room
          <svg
            class="ms-2 h-3.5 w-3.5 rtl:rotate-180"
            aria-hidden="true"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 14 10"
          >
            <path
              stroke="currentColor"
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M1 5h12m0 0L9 1m4 4L9 9"
            />
          </svg>
        </button>
      </form>

      <div>
        <button
          type="button"
          phx-click="create_room"
          class="inline-flex items-center rounded-lg bg-blue-700 px-5 py-2.5 text-center text-sm font-medium text-white hover:bg-blue-800 focus:outline-none focus:ring-4 focus:ring-blue-300 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
        >
          Create new room
          <svg
            class="ms-2 h-5 w-5"
            aria-hidden="true"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
          >
            <path
              stroke="currentColor"
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M5 12h14m-7 7V5"
            />
          </svg>
        </button>
      </div>
    </div>
    """
  end

  ###
  ### Event handlers
  ###

  @impl true
  def handle_event("join_room", %{"room_number" => room_number}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/#{room_number}")}
  end

  @impl true
  def handle_event("create_room", _, socket) do
    {:noreply, create_room(socket)}
  end

  ###
  ### Private functions
  ###

  defp create_room(socket) do
    case Rooms.create_room() do
      {:ok, room_id} ->
        # Success: Navigate to the new room
        push_navigate(socket, to: ~p"/#{room_id}")

      {:error, :room_limit_reached} ->
        # Failure: Notify the user
        put_flash(socket, :error, "Room limit reached. Please try again later.")

      {:error, reason} ->
        # General error handling
        put_flash(socket, :error, "Failed to create room: #{inspect(reason)}")
    end
  end
end
