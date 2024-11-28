defmodule PlanningPokerWeb.RoomLive.Show do
  use PlanningPokerWeb, :live_view

  alias PlanningPoker.Rooms
  alias PlanningPoker.Rooms.RoomState
  alias PlanningPokerWeb.Presence
  alias Phoenix.PubSub

  @pubsub_server PlanningPoker.PubSub

  @impl true
  def mount(%{"id" => room_id}, _session, socket) do
    if connected?(socket) do
      topic = "room:#{room_id}"
      PubSub.subscribe(@pubsub_server, topic)

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

      {:ok, assign(socket, :users, Presence.list(topic))}
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
      <h2 class="mb-4 text-2xl font-bold leading-none tracking-tight text-gray-900 md:text-3xl lg:text-4xl sm:px-16 xl:px-48 dark:text-white">
        Room <%= @room.id %>
      </h2>

      <div class="mb-4">
        <h3 class="text-lg font-semibold">Connected Users</h3>
        <ul class="list-disc pl-5">
          <%= for {_socket_id, presence} <- sort_users(@users) do %>
            <li class="text-sm text-gray-600">
              <%= presence.metas |> List.first() |> Map.get(:user_id) %>
            </li>
          <% end %>
        </ul>
      </div>

      <p class="mb-8 text-lg font-normal text-gray-500 lg:text-xl sm:px-16 xl:px-48 dark:text-gray-400">
        Mode: <%= @room.mode %>
      </p>
      <form phx-change="mode_changed">
        <input type="hidden" name="room[id]" value={@room.id} />
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

  defp mode_options do
    [
      {"Mountain Goat", :mountain_goat},
      {"Fibonacci", :fibonacci},
      {"Sequential", :sequential},
      {"Playing Cards", :playing_cards},
      {"T-Shirt Sizes", :t_shirt_sizes}
    ]
  end

  @impl true
  def handle_event("mode_changed", %{"room" => %{"id" => room_id, "mode" => new_mode}}, socket) do
    new_mode_atom = String.to_existing_atom(new_mode)
    Rooms.set_room_mode(room_id, new_mode_atom)
    {:noreply, assign(socket, room: %{socket.assigns.room | mode: new_mode_atom})}
  end

  @impl true
  def handle_event("user_id_available", %{"user_id" => user_id}, socket) do
    topic = "room:#{socket.assigns.room.id}"

    Presence.update(
      self(),
      topic,
      "user-#{socket.id}",
      &Map.put(&1, :user_id, user_id)
    )

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
  def handle_info(%{event: "presence_diff", payload: _diff}, socket) do
    # You can get the current users like this:
    users = Presence.list("room:#{socket.assigns.room.id}")
    {:noreply, assign(socket, :users, users)}
  end

  defp sort_users(users) do
    Enum.sort_by(users, fn {_, presence} ->
      presence.metas |> List.first() |> Map.get(:user_id)
    end)
  end
end
