defmodule SnackShop.Repo do
  use Ecto.Repo,
    otp_app: :snack_shop,
    adapter: Ecto.Adapters.Postgres
end
