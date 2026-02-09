defmodule SnackShop.Repo.Migrations.CreateProductIngredients do
  use Ecto.Migration

  def change do
    create table(:product_ingredients) do
      add :product_id, references(:products, on_delete: :delete_all), null: false
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:product_ingredients, [:product_id])
  end
end
