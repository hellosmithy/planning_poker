defmodule PlanningPoker.Rooms.Server do
  alias PlanningPoker.Rooms.RoomState
  alias Phoenix.PubSub

  use GenServer

  @registry PlanningPoker.Rooms.Registry
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

  def get_state(room_id) do
    GenServer.call(via_tuple(room_id), :get_room_state)
  end

  def update_state(room_id, partial_room_state) do
    GenServer.call(via_tuple(room_id), {:update_room_state, partial_room_state})
  end

  def set_room_mode(room_id, mode) do
    GenServer.call(via_tuple(room_id), {:set_room_mode, mode})
  end

  def set_user_selection(room_id, user_id, card_id) do
    GenServer.call(via_tuple(room_id), {:set_user_selection, user_id, card_id})
  end

  def reset_selections(room_id) do
    GenServer.call(via_tuple(room_id), {:reset_selections})
  end

  def reveal_selections(room_id) do
    GenServer.call(via_tuple(room_id), {:reveal_selections})
  end

  def generate_room_id do
    :rand.uniform(999_999) |> Integer.to_string() |> String.pad_leading(6, "0")
  end

  def max_rooms do
    Application.get_env(:planning_poker, :max_rooms, 1000)
  end

  def via_tuple(room_id), do: {:via, Registry, {@registry, room_id}}

  ###
  ### Server (callbacks)
  ###

  @impl GenServer
  def init(room_id) do
    IO.puts("Starting Rooms.Server: \"#{room_id}\"")
    Registry.register(@registry, room_id, :ok)
    {:ok, RoomState.new(room_id), @idle_timeout}
  end

  @impl GenServer
  def handle_call(:get_room_state, _, room) do
    {:reply, room, room, @idle_timeout}
  end

  @impl GenServer
  def handle_call({:update_room_state, partial_room_state}, _, room) do
    new_room =
      room
      |> RoomState.update(partial_room_state)
      |> broadcast_room_state(:update_room_state)

    {:reply, new_room, new_room, @idle_timeout}
  end

  @impl GenServer
  def handle_call({:set_room_mode, mode}, _, room) do
    new_room =
      room
      |> RoomState.set_mode(mode)
      |> broadcast_room_state(:set_room_mode)

    {:reply, new_room, new_room, @idle_timeout}
  end

  @impl GenServer
  def handle_call({:set_user_selection, user_id, card_id}, _, room) do
    new_room =
      room
      |> RoomState.set_user_selection(user_id, card_id)
      |> broadcast_room_state(:set_user_selection)

    {:reply, new_room, new_room, @idle_timeout}
  end

  @impl GenServer
  def handle_call({:reset_selections}, _, room) do
    new_room =
      room
      |> RoomState.reset_selections()
      |> broadcast_room_state(:reset_selections)

    {:reply, new_room, new_room, @idle_timeout}
  end

  @impl GenServer
  def handle_call({:reveal_selections}, _, room) do
    new_room =
      room
      |> RoomState.reveal_selections()
      |> broadcast_room_state(:reveal_selections)

    {:reply, new_room, new_room, @idle_timeout}
  end

  @impl true
  def handle_info(:timeout, state) do
    IO.puts("Terminating Rooms.Server for room #{state.id} due to inactivity.")
    {:stop, :normal, state}
  end

  @spec broadcast_room_state(RoomState.t(), term()) :: RoomState.t()
  defp broadcast_room_state(%RoomState{} = state, update_type) do
    PubSub.broadcast(@pubsub_server, "room:#{state.id}", {:room_state, state, update_type})
    state
  end
end
