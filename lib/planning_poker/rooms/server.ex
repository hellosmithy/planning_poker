defmodule PlanningPoker.Rooms.Server do
  alias PlanningPoker.Rooms.RoomState
  alias PlanningPoker.Config
  alias Phoenix.PubSub

  use GenServer

  @registry PlanningPoker.Rooms.Registry
  @superviser PlanningPoker.Rooms.Supervisor
  @pubsub_server PlanningPoker.PubSub
  @idle_timeout :timer.minutes(30)

  def start_link(room_id) do
    GenServer.start_link(__MODULE__, room_id, name: via_tuple(room_id))
  end

  def child_spec(room_id) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [room_id]},
      restart: :transient,
      type: :worker
    }
  end

  def create_room() do
    with true <- Registry.count(@registry) < max_rooms(),
         {:ok, room_id} <- generate_room_id(),
         {:ok, _pid} <- DynamicSupervisor.start_child(@superviser, {__MODULE__, room_id}) do
      {:ok, room_id}
    else
      false -> {:error, :room_limit_reached}
      {:error, :room_id_collision} -> {:error, :room_id_collision}
      {:error, reason} -> {:error, reason}
    end
  end

  def get_state(room_id) do
    case Registry.lookup(@registry, room_id) do
      [] ->
        {:error, :room_not_found}

      [{pid, _meta}] ->
        GenServer.call(pid, :get_room)
    end
  end

  def set_mode(room_id, mode) do
    GenServer.cast(via_tuple(room_id), {:set_mode, mode})
  end

  def get_mode(room_id) do
    GenServer.call(via_tuple(room_id), :get_mode)
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
    Registry.lookup(@registry, room_id) != []
  end

  defp generate_unique_id do
    :rand.seed(:exsplus, :os.timestamp())
    id = :rand.uniform(999_999) |> Integer.to_string() |> String.pad_leading(6, "0")
    id
  end

  defp max_rooms do
    Config.get_env(:max_rooms, 1000)
  end

  def via_tuple(room_id), do: {:via, Registry, {PlanningPoker.Rooms.Registry, room_id}}
  ###
  ### Server (callbacks)
  ###

  @impl GenServer
  def init(room_id) do
    IO.puts("Starting Rooms.Server: \"#{room_id}\"")
    Registry.register(PlanningPoker.Rooms.Registry, room_id, :ok)
    {:ok, RoomState.new(room_id), @idle_timeout}
  end

  @impl GenServer
  def handle_call(:get_room, _, room) do
    {:reply, room, room, @idle_timeout}
  end

  @impl GenServer
  def handle_call(:get_mode, _, room) do
    {:reply, room.mode, room, @idle_timeout}
  end

  @impl GenServer
  def handle_cast({:set_mode, mode}, room) do
    new_room =
      room
      |> RoomState.set_mode(mode)
      |> broadcast_room_state()

    {:noreply, new_room, @idle_timeout}
  end

  @impl true
  def handle_info(:timeout, state) do
    IO.puts("Terminating Rooms.Server for room #{state.id} due to inactivity.")
    {:stop, :normal, state}
  end

  defp broadcast_room_state(%RoomState{} = state) do
    PubSub.broadcast(@pubsub_server, "room:#{state.id}", {:room_state, state})
    state
  end
end
