defmodule MyApp.Repo.Migrations.CreateUsers do
  use Ecto.Migration

defmodule SnackShop.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :password_hash, :string
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :phone_number, :string, null: false
      add :google_id, :string
      add :role, :string, default: "customer", null: false
      add :confirmed_at, :naive_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:google_id])
    create index(:users, [:role])
  end
end
end
