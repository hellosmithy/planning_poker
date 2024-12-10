defmodule PlanningPokerWeb.RoomLive.Components.Cards do
  use Phoenix.Component

  attr(:selected?, :boolean, required: true)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def card(assigns) do
    ~H"""
    <button class={get_card_class(@selected?)} {@rest}>
      {render_slot(@inner_block)}
    </button>
    """
  end

  defp get_card_class(true),
    do:
      "block w-14 h-20 text-center flex items-center justify-center border border-white rounded-sm shadow bg-green-800 hover:bg-green-700 text-white"

  defp get_card_class(false),
    do:
      "block w-14 h-20 text-center flex items-center justify-center border border-white rounded-sm shadow bg-blue-800 hover:bg-blue-700 text-white"
end
