defmodule SnackShop.Products.ProductIngredient do
  @moduledoc """
  Product ingredient schema for tracking ingredients in food items.

  Examples for Bajia:
  - Lentils (Gram Dal)
  - Onions
  - Green Chilies
  - Coriander
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "product_ingredients" do
    field :name, :string

    # Associations
    belongs_to :product, SnackShop.Products.Product

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating/updating product ingredients.
  """
  def changeset(ingredient, attrs) do
    ingredient
    |> cast(attrs, [:product_id, :name])
    |> validate_required([:name])
    |> validate_length(:name, min: 2, max: 200)
    |> foreign_key_constraint(:product_id)
  end
end
