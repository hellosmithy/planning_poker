defmodule PlanningPokerWeb.RoomLive.Show do
  use PlanningPokerWeb, :live_view

  alias PlanningPoker.Rooms
  alias PlanningPoker.Rooms.RoomState
  alias PlanningPokerWeb.Presence
  alias Phoenix.LiveView.Socket
  alias Phoenix.PubSub

  @pubsub_server PlanningPoker.PubSub

  ###
  ### Lifecycle
  ###

  @impl true
  def mount(%{"id" => room_id}, _session, socket) do
    if connected?(socket) do
      topic = get_presence_topic(room_id)
      PubSub.subscribe(@pubsub_server, topic)

      {:ok,
       socket
       |> presence_track_user(topic)
       |> presence_assign_users(topic)}
    else
      {:ok, assign(socket, :users, %{})}
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
        Room <%= @room.id %>
      </h2>

      <div class="mb-4">
        <h3 class="text-lg font-semibold">Connected Users</h3>
        <ul class="list-disc pl-5">
          <%= for user <- sorted_users(@users) do %>
            <li class="text-sm text-gray-600"><%= user.user_id %></li>
          <% end %>
        </ul>
      </div>

      <p class="mb-8 text-lg font-normal text-gray-500 lg:text-xl sm:px-16 dark:text-gray-400">
        Mode: <%= @room.mode %>
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
  def handle_event("local_session_id_available", %{"user_id" => user_id}, socket) do
    {:noreply, presence_add_active_user(socket, user_id)}
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
  def handle_info(%{event: "presence_diff", payload: _diff}, socket) do
    {:noreply, socket |> assign_user_list()}
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

  @spec get_presence_topic(room_id_or_socket :: String.t() | Socket.t()) :: String.t()
  defp get_presence_topic(%Socket{} = socket), do: get_presence_topic(socket.assigns.room.id)
  defp get_presence_topic(room_id), do: "room:#{room_id}"

  @spec assign_user_list(socket :: Socket.t()) :: Socket.t()
  defp assign_user_list(socket) do
    assign(socket, :users, Presence.list(get_presence_topic(socket)))
  end

  @spec sorted_users(users :: Phoenix.Presence.presences()) :: [map()]
  defp sorted_users(users) do
    users
    |> Enum.map(fn {_, presence} ->
      presence.metas |> List.first()
    end)
    |> Enum.uniq_by(& &1.user_id)
    |> Enum.sort_by(& &1.user_id)
  end

  @spec set_room_mode(socket :: Socket.t(), new_mode :: String.t()) :: Socket.t()
  defp set_room_mode(socket, new_mode) do
    new_mode_atom = String.to_existing_atom(new_mode)
    Rooms.set_room_mode(socket.assigns.room.id, new_mode_atom)
    assign(socket, room: %{socket.assigns.room | mode: new_mode_atom})
  end

  @spec presence_add_active_user(socket :: Socket.t(), user_id :: String.t()) :: Socket.t()
  defp presence_add_active_user(socket, user_id) do
    topic = get_presence_topic(socket)

    Presence.update(
      self(),
      topic,
      "user-#{socket.id}",
      &Map.put(&1, :user_id, user_id)
    )

    socket
  end

  @spec presence_track_user(socket :: Socket.t(), topic :: String.t()) :: Socket.t()
  defp presence_track_user(socket, topic) do
    {:ok, _} =
      Presence.track(
        self(),
        topic,
        "user-#{socket.id}",
        %{
          joined_at: inspect(System.system_time(:second)),
          user_id: nil
        }
      )

    socket
  end

  @spec presence_assign_users(socket :: Socket.t(), topic :: String.t()) :: Socket.t()
  defp presence_assign_users(socket, topic) do
    assign(socket, :users, Presence.list(topic))
  end
end
