defmodule SnackShop.Products.ProductVariant do
  @moduledoc """
  Product variant schema for different sizes, flavors, etc.

  Examples:
  - Blended Juice: Small, Medium, Large
  - Ice-pops: Strawberry, Mango, Orange
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "product_variants" do
    field :name, :string  # e.g., "Size", "Flavor"
    field :value, :string  # e.g., "Small", "Medium", "Large"
    field :price_adjustment, :decimal, default: Decimal.new("0.00")

    # Associations
    belongs_to :product, SnackShop.Products.Product
    # ✅ Specify foreign_key because database uses 'variant_id' not 'product_variant_id'
    has_many :cart_items, SnackShop.Cart.CartItem, foreign_key: :variant_id
    has_many :order_items, SnackShop.Orders.OrderItem, foreign_key: :variant_id

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating/updating product variants.
  """
  def changeset(variant, attrs) do
    variant
    |> cast(attrs, [:product_id, :name, :value, :price_adjustment])
    |> validate_required([:name, :value])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_length(:value, min: 1, max: 100)
    |> validate_number(:price_adjustment, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:product_id)
  end

  @doc """
  Calculates final price with adjustment.

  ## Examples

      iex> product = %Product{selling_price: Decimal.new("100")}
      iex> variant = %ProductVariant{price_adjustment: Decimal.new("50")}
      iex> ProductVariant.final_price(variant, product)
      Decimal.new("150")
  """
  def final_price(%__MODULE__{price_adjustment: adjustment}, product) do
    Decimal.add(product.selling_price, adjustment)
  end

  @doc """
  Returns display text for variant.

  ## Examples

      iex> variant = %ProductVariant{name: "Size", value: "Large"}
      iex> ProductVariant.display_text(variant)
      "Size: Large"
  """
  def display_text(%__MODULE__{name: name, value: value}) do
    "#{name}: #{value}"
  end
end
