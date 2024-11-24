defmodule PlanningPoker.Rooms do
  @moduledoc """
  The Rooms context.
  """

  @max_rooms 1000

  def create_room() do
    current_rooms = Registry.count(PlanningPoker.Rooms.Registry)

    if current_rooms >= @max_rooms do
      {:error, :room_limit_reached}
    else
      room_id = generate_unique_id()

      {:ok, _pid} =
        DynamicSupervisor.start_child(
          PlanningPoker.Rooms.Supervisor,
          {PlanningPoker.Rooms.Server, room_id}
        )

      {:ok, room_id}
    end
  end

  def get_room(room_id) do
    case Registry.lookup(PlanningPoker.Rooms.Registry, room_id) do
      [{pid, _}] -> {:ok, pid}
      [] -> {:error, :room_not_found}
    end
  end

  defp generate_unique_id do
    :rand.seed(:exsplus, :os.timestamp())
    id = :rand.uniform(999_999) |> Integer.to_string() |> String.pad_leading(6, "0")
    id
  end
end
