defmodule PlanningPokerWeb.RoomLive.Show do
  use PlanningPokerWeb, :live_view

  alias PlanningPoker.Rooms
  alias PlanningPoker.Rooms.RoomState
  alias Phoenix.PubSub

  @pubsub_server PlanningPoker.PubSub

  @impl true
  def mount(%{"id" => room_id} = _params, _session, socket) do
    if connected?(socket) do
      # Subscribe to room update notifications
      PubSub.subscribe(@pubsub_server, "room:#{room_id}")
      # send(self(), :load_game_state)
    end

    {:ok, socket}
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
    <h2 class="mb-4 text-2xl font-bold leading-none tracking-tight text-gray-900 md:text-3xl lg:text-4xl sm:px-16 xl:px-48 dark:text-white">
      Room <%= @room.id %>
    </h2>
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
  def handle_info({:room_state, %RoomState{} = state} = _event, socket) do
    updated_socket =
      socket
      |> clear_flash()
      |> assign(:room, state)

    {:noreply, updated_socket}
  end
end
