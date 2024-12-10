defmodule PlanningPokerWeb.RoomLive.Components.Cards do
  use Phoenix.Component

  attr(:selected?, :boolean, default: false)
  attr(:face, :atom, default: :up)
  attr(:rest, :global)
  slot(:inner_block)

  def card(assigns) do
    ~H"""
    <button
      class="flex h-20 w-14 items-center justify-center rounded-sm border border-white bg-blue-800 text-center text-white shadow data-[selected]:bg-green-800 hover:bg-blue-700 hover:data-[selected]:bg-green-700"
      data-selected={@selected?}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end
end
