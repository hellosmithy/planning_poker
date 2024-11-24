defmodule PlanningPokerWeb.RoomLive.Show do
  use PlanningPokerWeb, :live_view

  alias PlanningPoker.Rooms

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => room_id}, _, socket) do
    case Rooms.get_room(room_id) do
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
    """
  end
end
