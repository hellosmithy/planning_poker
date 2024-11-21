defmodule PlanningPoker.Rooms do
  defmodule Room do
    defstruct [:id]
  end

  @moduledoc """
  The Rooms context.
  """

  @doc """
  Returns the list of rooms.

  ## Examples

      iex> list_rooms()
      [%Room{}, ...]

  """
  def list_rooms do
    [
      %Room{id: 1},
      %Room{id: 2},
      %Room{id: 3},
      %Room{id: 4},
      %Room{id: 5}
    ]
  end

  @doc """
  Gets a single room.

  ## Examples

      iex> get_room(123)
      %Room{id: 123}

  """
  def get_room(id) when is_integer(id), do: Enum.find(list_rooms(), fn t -> t.id == id end)

  def get_room(id) when is_binary(id), do: id |> String.to_integer() |> get_room()

  @doc """
  Creates a room.

  ## Examples

      iex> create_room(%{field: value})
      {:ok, %Room{}}

  """
  def create_room(_attrs \\ %{}) do
    %Room{}
  end
end
