defmodule PlanningPokerWeb.Plugs.SessionUser do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id) || Nanoid.generate()

    user_name =
      get_session(conn, :user_name) ||
        MnemonicSlugs.generate_slug()
        |> String.split("-")
        |> Enum.map(&String.capitalize/1)
        |> Enum.join(" ")

    conn
    |> put_session(:user_id, user_id)
    |> put_session(:user_name, user_name)
  end
end
