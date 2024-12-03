defmodule PlanningPoker.Rooms.RoomState do
  @moduledoc "Represents a room in Planning Poker."

  @type mode :: :mountain_goat | :fibonacci | :sequential | :playing_cards | :t_shirt_sizes
  @type t :: %__MODULE__{id: integer, mode: mode}

  defstruct [:id, :mode]

  @modes [:mountain_goat, :fibonacci, :sequential, :playing_cards, :t_shirt_sizes]

  @spec new(id: integer()) :: t
  def new(id) do
    %__MODULE__{id: id, mode: :mountain_goat}
  end

  @spec update(t, map()) :: t
  def update(%__MODULE__{} = room, partial_room_state) do
    struct(room, partial_room_state)
  end

  @spec set_mode(t, mode) :: t
  def set_mode(%__MODULE__{} = room, mode) when mode in @modes do
    %__MODULE__{room | mode: mode}
  end

  @spec valid_mode?(mode) :: boolean
  def valid_mode?(mode), do: mode in @modes
end
