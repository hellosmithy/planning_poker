# Start ExUnit
ExUnit.start()

# Start Wallaby (E2E tests)
{:ok, _} = Application.ensure_all_started(:wallaby)
Application.put_env(:wallaby, :base_url, PlanningPokerWeb.Endpoint.url())
