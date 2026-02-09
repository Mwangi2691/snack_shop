defmodule SnackShop.Repo.Migrations.CreateProductVariants do
  use Ecto.Migration

  def change do
    create table(:product_variants) do
      add :product_id, references(:products, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :value, :string, null: false
      add :price_adjustment, :decimal, precision: 10, scale: 2, default: 0.00

      timestamps(type: :utc_datetime)
    end

    create index(:product_variants, [:product_id])
  end
end
