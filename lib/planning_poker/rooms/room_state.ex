defmodule PlanningPoker.Rooms.RoomState do
  @moduledoc "Represents a room in Planning Poker."

  alias PlanningPoker.Rooms.Decks

  @type t :: %__MODULE__{id: integer, mode: atom, deck: Decks.t()}

  defstruct [:id, :mode, :deck]

  @modes Decks.get_deck_types()

  @spec new(integer(), atom()) :: t
  def new(id, mode \\ :mountain_goat) do
    %__MODULE__{id: id, mode: mode, deck: Decks.get_deck(mode)}
  end

  @spec update(t, map()) :: t
  def update(%__MODULE__{} = room, partial_room_state) do
    room = struct(room, partial_room_state)
    if Map.has_key?(partial_room_state, :mode), do: set_mode(room, room.mode), else: room
  end

  @spec set_mode(t, atom()) :: t
  def set_mode(%__MODULE__{} = room, mode) when mode in @modes do
    %__MODULE__{room | mode: mode, deck: Decks.get_deck(mode)}
  end

  @spec valid_mode?(atom()) :: boolean
  def valid_mode?(mode), do: mode in @modes
end
