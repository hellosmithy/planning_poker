ExUnit.start()

# Start wallaby
{:ok, _} = Application.ensure_all_started(:wallaby)
Application.put_env(:wallaby, :base_url, PlanningPokerWeb.Endpoint.url())
