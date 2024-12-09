defmodule PlanningPoker.Rooms.Card do
  @moduledoc """
  Represents a card in the Planning Poker game.
  """

  @type t :: %__MODULE__{id: String.t(), label: String.t(), value: float() | nil}

  defstruct id: nil, label: nil, value: nil
end
