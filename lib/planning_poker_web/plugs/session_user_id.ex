defmodule PlanningPokerWeb.Plugs.SessionUserId do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id) || Nanoid.generate()

    conn
    |> put_session(:user_id, user_id)
  end
end
