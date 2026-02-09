defmodule SnackShop.Cart.CartItem do
  @moduledoc """
  Shopping cart item schema.

  Features:
  - Unique constraint on (user_id, product_id, variant_id)
  - Prevents duplicate cart entries
  - Quantity updates instead of duplicates
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "cart_items" do
    field :quantity, :integer, default: 1

    # Associations
    belongs_to :user, SnackShop.Accounts.User
    belongs_to :product, SnackShop.Products.Product
    # ✅ Explicitly name the foreign key as 'variant_id'
    belongs_to :variant, SnackShop.Products.ProductVariant, foreign_key: :variant_id

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating/updating cart items.
  """
  def changeset(cart_item, attrs) do
    cart_item
    |> cast(attrs, [:user_id, :product_id, :variant_id, :quantity])
    |> validate_required([:user_id, :product_id, :quantity])
    |> validate_number(:quantity, greater_than: 0, less_than_or_equal_to: 100)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:product_id)
    |> foreign_key_constraint(:variant_id)
    |> unique_constraint([:user_id, :product_id, :variant_id],
         name: :cart_items_user_id_product_id_variant_id_index,
         message: "Item already in cart")
  end

  @doc """
  Calculates subtotal for this cart item.

  ## Examples

      iex> product = %Product{selling_price: Decimal.new("100")}
      iex> variant = %ProductVariant{price_adjustment: Decimal.new("50")}
      iex> cart_item = %CartItem{quantity: 2, product: product, variant: variant}
      iex> CartItem.subtotal(cart_item)
      Decimal.new("300")
  """
  def subtotal(%__MODULE__{quantity: qty, product: product, variant: nil}) do
    product.selling_price
    |> Decimal.mult(qty)
  end

  def subtotal(%__MODULE__{quantity: qty, product: product, variant: variant}) do
    final_price = SnackShop.Products.ProductVariant.final_price(variant, product)
    Decimal.mult(final_price, qty)
  end

  @doc """
  Gets the unit price for this cart item (considering variant).
  """
  def unit_price(%__MODULE__{product: product, variant: nil}) do
    product.selling_price
  end

  def unit_price(%__MODULE__{product: product, variant: variant}) do
    SnackShop.Products.ProductVariant.final_price(variant, product)
  end
end
