defmodule PlanningPoker.Rooms do
  @moduledoc """
  The Rooms context.
  """

  alias PlanningPoker.Rooms.Server
  alias PlanningPoker.Rooms.Room

  @max_rooms 1000

  def create_room() do
    with true <- Registry.count(PlanningPoker.Rooms.Registry) < @max_rooms,
         {:ok, room_id} <- generate_room_id(),
         {:ok, _pid} <- start_room(room_id) do
      {:ok, room_id}
    else
      false -> {:error, :room_limit_reached}
      {:error, :room_id_collision} -> {:error, :room_id_collision}
      {:error, reason} -> {:error, reason}
    end
  end

  def get_room(room_id) do
    case Registry.lookup(PlanningPoker.Rooms.Registry, room_id) do
      [{pid, _}] ->
        case Server.get_room(pid) do
          %Room{} = room -> {:ok, room}
          error -> error
        end

      [] ->
        {:error, :room_not_found}
    end
  end

  defp start_room(room_id) do
    DynamicSupervisor.start_child(
      PlanningPoker.Rooms.Supervisor,
      {PlanningPoker.Rooms.Server, room_id}
    )
  end

  defp generate_room_id(retries \\ 5)

  defp generate_room_id(0), do: {:error, :room_id_collision}

  defp generate_room_id(retries) do
    room_id = generate_unique_id()

    case room_exists?(room_id) do
      true -> generate_room_id(retries - 1)
      false -> {:ok, room_id}
    end
  end

  defp room_exists?(room_id) do
    Registry.lookup(PlanningPoker.Rooms.Registry, room_id) != []
  end

  defp generate_unique_id do
    :rand.seed(:exsplus, :os.timestamp())
    id = :rand.uniform(999_999) |> Integer.to_string() |> String.pad_leading(6, "0")
    id
  end
end
