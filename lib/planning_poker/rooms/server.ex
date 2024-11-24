defmodule PlanningPoker.Rooms.Server do
  alias PlanningPoker.Rooms.Room

  use GenServer

  @idle_timeout :timer.minutes(30)

  def start_link(room_id) do
    GenServer.start_link(__MODULE__, room_id, name: via_tuple(room_id))
  end

  defp via_tuple(room_id) do
    {:via, Registry, {PlanningPoker.Rooms.Registry, room_id}}
  end

  def child_spec(room_id) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [room_id]},
      restart: :transient,
      type: :worker
    }
  end

  def set_mode(room_server, mode) do
    GenServer.cast(room_server, {:set_mode, mode})
  end

  def get_mode(room_server) do
    GenServer.call(room_server, :get_mode)
  end

  @impl GenServer
  def init(room_id) do
    IO.puts("Starting Room.Server: \"#{room_id}\"")
    Registry.register(PlanningPoker.Rooms.Registry, room_id, :ok)
    {:ok, Room.new(room_id), @idle_timeout}
  end

  @impl GenServer
  def handle_call(:get_mode, _, room) do
    {:reply, room.mode, room, @idle_timeout}
  end

  @impl GenServer
  def handle_cast({:set_mode, mode}, room) do
    new_room = Room.set_mode(room, mode)
    {:noreply, new_room, @idle_timeout}
  end

  @impl true
  def handle_info(:timeout, state) do
    IO.puts("Terminating Room.Server for room #{state.id} due to inactivity.")
    {:stop, :normal, state}
  end
end
