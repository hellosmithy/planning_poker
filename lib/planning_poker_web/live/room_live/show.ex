defmodule PlanningPokerWeb.RoomLive.Show do
  use PlanningPokerWeb, :live_view

  alias PlanningPoker.Rooms

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:room, Rooms.get_room(id))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    Room <%= @room.id %>
    """
  end
end
