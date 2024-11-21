defmodule PlanningPokerWeb.RoomLive.Index do
  use PlanningPokerWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1>Planning Poker</h1>
    """
  end
end
