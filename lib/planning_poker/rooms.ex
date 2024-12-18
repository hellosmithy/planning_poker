defmodule PlanningPoker.Rooms do
  @moduledoc """
  The Rooms context.
  """

  alias PlanningPoker.Rooms.Server

  @registry PlanningPoker.Rooms.Registry
  @superviser PlanningPoker.Rooms.Supervisor

  def create_room() do
    with true <- Registry.count(@registry) < Server.max_rooms(),
         {:ok, room_id} <- generate_room_id(),
         {:ok, _pid} <- DynamicSupervisor.start_child(@superviser, {Server, room_id}) do
      {:ok, room_id}
    else
      false -> {:error, :room_limit_reached}
      {:error, :room_id_collision} -> {:error, :room_id_collision}
      {:error, reason} -> {:error, reason}
    end
  end

  def get_room_state(room_id) do
    call_or_error(fn -> Server.get_state(room_id) end, :room_not_found)
  end

  def set_room_mode(room_id, mode) do
    call_or_error(fn -> Server.set_room_mode(room_id, mode) end, :room_not_found)
  end

  def set_user_selection(room_id, user_id, card_id) do
    call_or_error(fn -> Server.set_user_selection(room_id, user_id, card_id) end, :room_not_found)
  end

  def reset_selections(room_id) do
    call_or_error(fn -> Server.reset_selections(room_id) end, :room_not_found)
  end

  def reveal_selections(room_id) do
    call_or_error(fn -> Server.reveal_selections(room_id) end, :room_not_found)
  end

  defp generate_room_id(retries \\ 5)

  defp generate_room_id(0), do: {:error, :room_id_collision}

  defp generate_room_id(retries) do
    room_id = Server.generate_room_id()

    case room_exists?(room_id) do
      true -> generate_room_id(retries - 1)
      false -> {:ok, room_id}
    end
  end

  defp room_exists?(room_id) do
    Registry.lookup(@registry, room_id) != []
  end

  defp call_or_error(fun, error_type) do
    try do
      {:ok, fun.()}
    catch
      :exit, {:noproc, _reason} -> {:error, error_type}
      :error, reason -> {:error, reason}
    end
  end
end
