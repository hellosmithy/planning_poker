defmodule PlanningPokerWeb.RoomLive.Components.Cards do
  use Phoenix.Component

  attr(:selected?, :boolean, default: false)
  attr(:disabled?, :boolean, default: false)
  attr(:face, :atom, default: :up)
  attr(:rest, :global)
  slot(:inner_block)

  def card(assigns) do
    ~H"""
    <button
      class="flex h-20 w-14 items-center justify-center rounded-sm border border-white bg-blue-800 text-center text-white shadow data-[selected]:bg-green-800 hover:bg-blue-700 hover:data-[selected]:bg-green-700 disabled:opacity-50 disabled:hover:bg-blue-800 disabled:hover:data-[selected]:bg-green-800"
      data-selected={@selected?}
      data-face={@face}
      disabled={@disabled?}
      {@rest}
    >
      <%= if @face == :up do %>
        {render_slot(@inner_block)}
      <% end %>
    </button>
    """
  end

  def empty_card(assigns) do
    ~H"""
    <div class="flex h-20 w-14 items-center justify-center rounded-sm border border-gray-500 shadow" />
    """
  end
end
