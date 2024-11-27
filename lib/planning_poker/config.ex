defmodule PlanningPoker.Config do
  @doc """
  Gets a value from config, supporting system environment variables.

  ## Examples
      iex> Config.get_env(:max_rooms, 100)
      100

      iex> System.put_env("MAX_ROOMS", "50")
      iex> Config.get_env(:max_rooms, 100)
      50
  """
  def get_env(key, default \\ nil) do
    case Application.get_env(:planning_poker, key) do
      {:system, env_var, default_value} ->
        System.get_env(env_var) |> parse_env_value() || default_value

      value ->
        value || default
    end
  end

  # Convert string values to integers when needed
  defp parse_env_value(nil), do: nil

  defp parse_env_value(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} -> int
      _ -> value
    end
  end
end
