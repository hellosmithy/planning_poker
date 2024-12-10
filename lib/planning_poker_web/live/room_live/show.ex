defmodule PlanningPokerWeb.RoomLive.Show do
  use PlanningPokerWeb, :live_view

  require Logger

  import PlanningPokerWeb.RoomLive.Components.Cards

  alias PlanningPoker.Rooms
  alias PlanningPoker.Rooms.Decks
  alias PlanningPoker.Rooms.RoomState
  alias PlanningPokerWeb.Presence
  alias Phoenix.LiveView.Socket
  alias Phoenix.PubSub

  @pubsub_server PlanningPoker.PubSub

  ###
  ### Lifecycle
  ###

  @impl true
  def mount(%{"id" => room_id}, session, socket) do
    user_id = session["user_id"]

    if connected?(socket) do
      topic = "room:#{room_id}"
      PubSub.subscribe(@pubsub_server, topic)
      presence_track_user(topic, user_id)

      {:ok,
       socket
       |> assign(:user_id, user_id)
       |> assign(:topic, topic)
       |> assign(:selected_card_id, nil)
       |> assign_user_list()}
    else
      {:ok,
       socket
       |> assign(:user_id, user_id)
       |> assign(:selected_card_id, nil)
       |> assign(:users, %{})}
    end
  end

  @impl true
  def handle_params(%{"id" => room_id}, _, socket) do
    case Rooms.get_room_state(room_id) do
      {:ok, room} ->
        {:noreply, assign(socket, room: room)}

      {:error, :room_not_found} ->
        {:noreply, socket |> put_flash(:error, "Room not found!") |> redirect(to: "/")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="room" data-room-id={@room.id} phx-hook="GetUserId">
      <h2 class="mb-4 text-2xl font-bold leading-none tracking-tight text-gray-900 md:text-3xl lg:text-4xl sm:px-16 dark:text-white">
        Room {@room.id}
      </h2>

      <div class="mb-4">
        <h3 class="text-lg font-semibold">Connected Users</h3>
        <ul class="list-disc pl-5">
          <%= for user_id <- get_user_ids(@users) do %>
            <li class="text-sm text-gray-600">{user_id}</li>
          <% end %>
        </ul>
      </div>

      <p class="mb-8 text-lg font-normal text-gray-500 lg:text-xl sm:px-16 dark:text-gray-400">
        Mode: {@room.mode}
      </p>
      <form phx-change="mode_changed">
        <.input
          type="select"
          id="room_mode"
          name="room[mode]"
          label="Select a mode"
          options={mode_options()}
          value={@room.mode}
          data-value={@room.mode}
          phx-hook="SyncDataValue"
        />
      </form>

      <div class="flex flex-wrap gap-4 py-8">
        <.card
          :for={card <- get_cards(@room.deck)}
          phx-click="select_card"
          phx-value-id={card.id}
          selected?={@selected_card_id == card.id}
        >
          {card.label}
        </.card>
        <%!-- <button
          :for={{label, value} <- get_cards(@room.deck)}
          class="block w-14 h-20 text-center flex items-center justify-center border border-white rounded-sm shadow hover:bg-blue-100 bg-blue-800 hover:bg-blue-700 text-white"
          phx-click="select_card"
          data-value={value}
        >
          <%= label %>
        </button> --%>
      </div>

      <div>
        <p class="mb-8 text-lg font-normal text-gray-500 lg:text-xl sm:px-16 dark:text-gray-400">
          You haven't estimated yet
        </p>
      </div>

      <div class="flex flex-wrap gap-4 py-8">
        <div
          :for={_user_id <- get_user_ids(@users)}
          class="block w-14 h-20 flex items-center justify-center border-gray-500 border rounded-sm shadow"
        >
        </div>
      </div>

      <div class="flex gap-4 py-8">
        <button
          type="button"
          class="text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center inline-flex items-center dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
        >
          Reset
          <svg
            class="w-5 h-5 ms-2"
            aria-hidden="true"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            stroke="currentColor"
            stroke-width="1.5"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0 3.181 3.183a8.25 8.25 0 0 0 13.803-3.7M4.031 9.865a8.25 8.25 0 0 1 13.803-3.7l3.181 3.182m0-4.991v4.99"
            />
          </svg>
        </button>

        <button
          type="button"
          class="text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center inline-flex items-center dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
        >
          Reveal
          <svg
            class="w-5 h-5 ms-2"
            aria-hidden="true"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            stroke="currentColor"
            stroke-width="1.5"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="m15 15-6 6m0 0-6-6m6 6V9a6 6 0 0 1 12 0v3"
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
  def handle_event("mode_changed", %{"room" => %{"mode" => new_mode}}, socket) do
    {:noreply, set_room_mode(socket, new_mode)}
  end

  @impl true
  def handle_event("select_card", %{"id" => id}, socket)
      when id == socket.assigns.selected_card_id,
      do: {:noreply, assign(socket, selected_card_id: nil)}

  def handle_event("select_card", %{"id" => id}, socket),
    do: {:noreply, assign(socket, selected_card_id: id)}

  @impl true
  def handle_info({:room_state, %RoomState{} = state} = _event, socket) do
    updated_socket =
      socket
      |> clear_flash()
      |> assign(:room, state)

    {:noreply, updated_socket}
  end

  @impl true
  def handle_info(%{event: "presence_diff", payload: payload}, socket) do
    Logger.debug("Presence #{socket.assigns.topic} (joins): #{inspect(payload.joins)}")
    Logger.debug("Presence #{socket.assigns.topic} (leaves): #{inspect(payload.leaves)}")

    {:noreply, assign_user_list(socket)}
  end

  ###
  ### Private functions
  ###

  @spec mode_options() :: [{String.t(), atom()}]
  defp mode_options do
    [
      {"Mountain Goat", :mountain_goat},
      {"Fibonacci", :fibonacci},
      {"Sequential", :sequential},
      {"Playing Cards", :playing_cards},
      {"T-Shirt Sizes", :t_shirt_sizes}
    ]
  end

  @spec assign_user_list(socket :: Socket.t()) :: Socket.t()
  defp assign_user_list(socket) do
    assign(socket, :users, Presence.list(socket.assigns.topic))
  end

  @spec get_user_ids(users :: Phoenix.Presence.presences()) :: [String.t()]
  defp get_user_ids(users) do
    users
    |> Enum.map(fn {user_id, _presence} -> user_id end)
    |> Enum.sort()
  end

  @spec set_room_mode(socket :: Socket.t(), new_mode :: String.t()) :: Socket.t()
  defp set_room_mode(socket, new_mode) do
    new_mode_atom = String.to_existing_atom(new_mode)
    Rooms.set_room_mode(socket.assigns.room.id, new_mode_atom)
    assign(socket, room: %{socket.assigns.room | mode: new_mode_atom})
  end

  @spec presence_track_user(topic :: String.t(), user_id :: String.t()) ::
          {:ok, ref :: binary()} | {:error, reason :: term()}
  defp presence_track_user(topic, user_id) do
    Logger.debug("Presence tracking user: #{user_id}")

    Presence.track(
      self(),
      topic,
      user_id,
      %{joined_at: inspect(System.system_time(:second))}
    )
  end

  @spec get_cards(deck :: Decks.t()) :: [{String.t(), integer() | nil}]
  defp get_cards({_, cards}) do
    cards
  end
end
