defmodule SnackShop.Repo.Migrations.CreateCartItems do
  use Ecto.Migration

  def change do
    create table(:cart_items) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :product_id, references(:products, on_delete: :delete_all), null: false
      add :variant_id, references(:product_variants, on_delete: :nilify_all)
      add :quantity, :integer, null: false, default: 1

      timestamps(type: :utc_datetime)
    end

    create index(:cart_items, [:user_id])
    create unique_index(:cart_items, [:user_id, :product_id, :variant_id])
  end
end
