defmodule SnackShop.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :category_id, references(:categories, on_delete: :restrict), null: false
      add :name, :string, null: false
      add :description, :text
      add :cost_price, :decimal, precision: 10, scale: 2, null: false
      add :selling_price, :decimal, precision: 10, scale: 2, null: false
      add :stock_quantity, :integer, default: 0
      add :image_url, :string
      add :is_available, :boolean, default: true
      add :slug, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:products, [:category_id])
    create unique_index(:products, [:slug])
    create index(:products, [:is_available])
  end
end
