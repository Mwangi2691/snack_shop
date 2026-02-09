defmodule SnackShop.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders) do
      add :user_id, references(:users, on_delete: :restrict), null: false
      add :order_number, :string, null: false
      add :status, :string, default: "pending", null: false
      add :total_amount, :decimal, precision: 10, scale: 2, null: false
      add :payment_method, :string, default: "cash", null: false
      add :payment_status, :string, default: "pending", null: false
      add :delivery_address, :text
      add :delivery_phone, :string
      add :notes, :text
      add :confirmed_at, :naive_datetime
      add :delivered_at, :naive_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:orders, [:user_id])
    create unique_index(:orders, [:order_number])
    create index(:orders, [:status])
    create index(:orders, [:inserted_at])
  end
end
