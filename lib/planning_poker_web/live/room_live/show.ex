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
    user_name = session["user_name"]

    if connected?(socket) do
      topic = "room:#{room_id}"
      PubSub.subscribe(@pubsub_server, topic)
      presence_track_user(topic, user_id, user_name)

      {:ok,
       socket
       |> assign(:user_id, user_id)
       |> assign(:user_name, user_name)
       |> assign(:topic, topic)
       |> assign_user_list()}
    else
      {:ok,
       socket
       |> assign(:user_id, user_id)
       |> assign(:user_name, user_name)
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
        <h3 class="text-lg font-semibold text-white">Connected Users</h3>
        <ul class="list-disc pl-5">
          <%= for user <- @users do %>
            <div
              class="relative inline-flex h-10 w-10 items-center justify-center rounded-full bg-gray-100 dark:bg-gray-600"
              data-tooltip-target={"tooltip-user-#{user.id}"}
            >
              <span
                class="cursor-default font-medium text-gray-600 dark:text-gray-300"
                title={user.name}
              >
                {get_name_initials(user.name)}
              </span>
              <span class="absolute bottom-0 left-7 h-3.5 w-3.5 rounded-full border-2 border-white bg-green-400 dark:border-gray-800">
              </span>
            </div>
            <div
              role="tooltip"
              id={"tooltip-user-#{user.id}"}
              data-tooltip={"tooltip-user-#{user.id}"}
              data-tooltip-placement="bottom"
              class="font-sans invisible absolute z-50 whitespace-normal break-words rounded-lg bg-black px-3 py-1.5 text-sm font-normal text-white focus:outline-none"
            >
              {user.name}
            </div>
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
        <p class="mb-8 text-lg font-normal text-gray-500 dark:text-gray-400 lg:text-xl">
          <%= case get_selection(@room, @user_id) do %>
            <% nil -> %>
              You haven't estimated yet
            <% card -> %>
              You have estimated {get_estimate(card, :label)}
          <% end %>
        </p>
      </div>

      <div class="flex flex-wrap gap-4 py-8">
        <%= for user <- @users do %>
          <%= if @room.user_selections[user.id] != nil do %>
            <.card face={:down} selected?={user.id == @user_id}></.card>
          <% else %>
            <.empty_card />
          <% end %>
        <% end %>
      </div>

      <div class="flex gap-4 py-8">
        <button
          type="button"
          phx-click="reset_selections"
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

  @impl true
  def handle_event("set_selected_card", %{"user-id" => user_id, "card-id" => card_id}, socket) do
    Logger.debug("Setting user selection for user: #{user_id} to card: #{card_id}")
    Rooms.set_user_selection(socket.assigns.room.id, user_id, card_id)
    {:noreply, socket}
  end

  @impl true
  def handle_event("set_selected_card", %{"user-id" => user_id}, socket) do
    Logger.debug("Resetting user selection for user: #{user_id}")
    Rooms.set_user_selection(socket.assigns.room.id, user_id, nil)
    {:noreply, socket}
  end

  @impl true
  def handle_event("reset_selections", _, socket) do
    Logger.debug("Resetting user selections")
    Rooms.reset_selections(socket.assigns.room.id)
    {:noreply, socket |> put_flash(:info, "Board reset")}
  end

  @impl true
  def handle_info({:room_state, %RoomState{} = state, update_type} = _event, socket) do
    {:noreply, socket |> update_room_state(state, update_type)}
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
    users =
      Presence.list(socket.assigns.topic)
      |> Enum.map(fn {user_id, %{metas: [meta | _]}} -> %{id: user_id, name: meta.user_name} end)
      |> Enum.sort_by(&Map.get(&1, :id))

    assign(socket, :users, users)
  end

  @spec presence_track_user(topic :: String.t(), user_id :: String.t(), user_name :: String.t()) ::
          {:ok, ref :: binary()} | {:error, reason :: term()}
  defp presence_track_user(topic, user_id, user_name) do
    Logger.debug("Presence tracking user: #{user_id}")

    Presence.track(
      self(),
      topic,
      user_id,
      %{joined_at: inspect(System.system_time(:second)), user_name: user_name}
    )
  end

  @spec get_cards(deck :: Decks.t()) :: [{String.t(), integer() | nil}]
  defp get_cards({_, cards}) do
    cards
  end

  @spec get_selection(room :: RoomState.t(), user_id :: String.t()) :: Card.t() | nil
  defp get_selection(room, user_id),
    do: Decks.get_card_by_id(room.deck, room.user_selections[user_id])

  @spec get_estimate(card :: Card.t() | nil, :label | :value) :: String.t() | integer() | nil
  defp get_estimate(nil, _), do: nil
  defp get_estimate(card, :label), do: card.label
  defp get_estimate(card, :value), do: card.value

  @spec get_name_initials(String.t()) :: String.t()
  defp get_name_initials(name) do
    name
    |> String.split(" ")
    |> Enum.map(&String.at(&1, 0))
    |> Enum.join("")
  end

  defp update_room_state(socket, room_state, :reset_selections) do
    socket
    |> assign(:room, room_state)
  end

  defp update_room_state(socket, room_state, _) do
    socket
    |> clear_flash()
    |> assign(:room, room_state)
  end
end
