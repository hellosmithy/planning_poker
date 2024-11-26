defmodule PlanningPokerWeb.RoomLive.Show do
  use PlanningPokerWeb, :live_view

  alias PlanningPoker.Rooms

  @impl true
  def mount(_params, _session, socket) do
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
      <form phx-change="mode_changed">
        <input type="hidden" name="room[id]" value={@room.id} />
        <.input
          type="select"
          id="room_mode"
          name="room[mode]"
          label="Select a mode"
          options={mode_options()}
          value={@room.mode}
        />
      </form>
    </p>
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

    case Rooms.set_room_mode(room_id, new_mode_atom) do
      :ok ->
        {:noreply, assign(socket, room: %{socket.assigns.room | mode: new_mode_atom})}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to update mode: #{reason}")}
    end
  end
end
