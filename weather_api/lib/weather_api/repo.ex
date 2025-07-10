defmodule WeatherApi.Repo do
  use Ecto.Repo,
    otp_app: :weather_api,
    adapter: Ecto.Adapters.Postgres
end
