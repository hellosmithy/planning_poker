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
       |> assign_user_list()}
    else
      {:ok,
       socket
       |> assign(:user_id, user_id)
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
      <h2 class="mb-4 text-2xl font-bold leading-none tracking-tight text-gray-900 dark:text-white sm:px-16 md:text-3xl lg:text-4xl">
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

      <p class="mb-8 text-lg font-normal text-gray-500 dark:text-gray-400 sm:px-16 lg:text-xl">
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
          phx-click="set_selected_card"
          phx-value-user-id={@user_id}
          phx-value-card-id={if @room.user_selections[@user_id] == card.id, do: nil, else: card.id}
          selected?={@room.user_selections[@user_id] == card.id}
        >
          {card.label}
        </.card>
      </div>

      <div>
        <p class="mb-8 text-lg font-normal text-gray-500 dark:text-gray-400 sm:px-16 lg:text-xl">
          You haven't estimated yet
        </p>
      </div>

      <div class="flex flex-wrap gap-4 py-8">
        <%= for user_id <- get_user_ids(@users) do %>
          <%= if @room.user_selections[user_id] != nil do %>
            <.card face={:down} selected?={user_id == @user_id}></.card>
          <% else %>
            <.empty_card />
          <% end %>
        <% end %>
      </div>

      <div class="flex gap-4 py-8">
        <button
          type="button"
          class="inline-flex items-center rounded-lg bg-blue-700 px-5 py-2.5 text-center text-sm font-medium text-white hover:bg-blue-800 focus:outline-none focus:ring-4 focus:ring-blue-300 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
        >
          Reset
          <svg
            class="ms-2 h-5 w-5"
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
          class="inline-flex items-center rounded-lg bg-blue-700 px-5 py-2.5 text-center text-sm font-medium text-white hover:bg-blue-800 focus:outline-none focus:ring-4 focus:ring-blue-300 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
        >
          Reveal
          <svg
            class="ms-2 h-5 w-5"
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
    Rooms.set_room_mode(socket.assigns.room.id, String.to_existing_atom(new_mode))
    {:noreply, socket}
  end

  def handle_event("set_selected_card", %{"user-id" => user_id, "card-id" => card_id}, socket) do
    Logger.debug("Setting user selection for user: #{user_id} to card: #{card_id}")
    Rooms.set_user_selection(socket.assigns.room.id, user_id, card_id)
    {:noreply, socket}
  end

  def handle_event("set_selected_card", %{"user-id" => user_id}, socket) do
    Logger.debug("Resetting user selection for user: #{user_id}")
    Rooms.set_user_selection(socket.assigns.room.id, user_id, nil)
    {:noreply, socket}
  end

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
