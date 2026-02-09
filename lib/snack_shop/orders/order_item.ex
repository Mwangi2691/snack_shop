defmodule SnackShop.Orders.OrderItem do
  @moduledoc """
  Order item schema representing individual items in an order.

  Important:
  - Stores unit_price and total_price to preserve historical pricing
  - Even if product price changes later, order shows original price
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "order_items" do
    field :quantity, :integer
    field :unit_price, :decimal  # Price at time of order
    field :total_price, :decimal # quantity * unit_price

    # Associations
    belongs_to :order, SnackShop.Orders.Order
    belongs_to :product, SnackShop.Products.Product
    # ✅ Explicitly name the foreign key as 'variant_id'
    belongs_to :variant, SnackShop.Products.ProductVariant, foreign_key: :variant_id

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating order items.
  """
  def changeset(order_item, attrs) do
    order_item
    |> cast(attrs, [:order_id, :product_id, :variant_id, :quantity, :unit_price, :total_price])
    |> validate_required([:order_id, :product_id, :quantity, :unit_price, :total_price])
    |> validate_number(:quantity, greater_than: 0)
    |> validate_number(:unit_price, greater_than_or_equal_to: 0)
    |> validate_number(:total_price, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:order_id)
    |> foreign_key_constraint(:product_id)
    |> foreign_key_constraint(:variant_id)
  end

  @doc """
  Creates order item from cart item.
  Captures current price at time of order.

  ## Examples

      iex> cart_item = %CartItem{
      ...>   product: %Product{selling_price: Decimal.new("100")},
      ...>   variant: %ProductVariant{price_adjustment: Decimal.new("50")},
      ...>   quantity: 2
      ...> }
      iex> OrderItem.from_cart_item(cart_item, order_id)
      %{
        order_id: order_id,
        product_id: cart_item.product_id,
        variant_id: cart_item.variant_id,
        quantity: 2,
        unit_price: Decimal.new("150"),
        total_price: Decimal.new("300")
      }
  """
  def from_cart_item(cart_item, order_id) do
    unit_price = SnackShop.Cart.CartItem.unit_price(cart_item)
    total_price = Decimal.mult(unit_price, cart_item.quantity)

    %{
      order_id: order_id,
      product_id: cart_item.product_id,
      variant_id: cart_item.variant_id,
      quantity: cart_item.quantity,
      unit_price: unit_price,
      total_price: total_price
    }
  end

  @doc """
  Calculates profit for this order item.
  Requires product to be preloaded.
  """
  def profit(%__MODULE__{quantity: qty, unit_price: unit_price, product: product}) do
    profit_per_unit = Decimal.sub(unit_price, product.cost_price)
    Decimal.mult(profit_per_unit, qty)
  end
end
