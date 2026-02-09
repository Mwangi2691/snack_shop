defmodule SnackShop.Products.Category do
  @moduledoc """
  Category schema for organizing products.
  Examples: Drinks, Snacks, Food
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "categories" do
    field :name, :string
    field :description, :string
    field :slug, :string

    # Associations
    has_many :products, SnackShop.Products.Product

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating/updating categories.
  Automatically generates slug from name.
  """
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :description, :slug])
    |> validate_required([:name])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_length(:description, max: 500)
    |> put_slug()
    |> unique_constraint(:name)
    |> unique_constraint(:slug)
  end

  defp put_slug(changeset) do
    case get_change(changeset, :name) do
      nil ->
        changeset
      name ->
        slug = name
        |> String.downcase()
        |> String.replace(~r/[^\w-]+/, "-")
        |> String.trim("-")

        put_change(changeset, :slug, slug)
    end
  end
end
