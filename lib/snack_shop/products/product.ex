defmodule SnackShop.Products.Product do
  @moduledoc """
  Product schema representing items for sale in the snack shop.

  Features:
  - Cost price tracking for profit calculations
  - Stock quantity management
  - Product variants (sizes, flavors)
  - Ingredients (for food items)
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :name, :string
    field :description, :string
    field :cost_price, :decimal
    field :selling_price, :decimal
    field :stock_quantity, :integer, default: 0
    field :image_url, :string
    field :is_available, :boolean, default: true
    field :slug, :string

    # Associations
    belongs_to :category, SnackShop.Products.Category
    has_many :variants, SnackShop.Products.ProductVariant, on_replace: :delete
    has_many :ingredients, SnackShop.Products.ProductIngredient, on_replace: :delete
    has_many :cart_items, SnackShop.Cart.CartItem
    has_many :order_items, SnackShop.Orders.OrderItem

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating/updating products.
  """
  def changeset(product, attrs) do
    product
    |> cast(attrs, [
      :category_id, :name, :description, :cost_price, :selling_price,
      :stock_quantity, :image_url, :is_available, :slug
    ])
    |> validate_required([:category_id, :name, :cost_price, :selling_price])
    |> validate_length(:name, min: 2, max: 200)
    |> validate_number(:cost_price, greater_than_or_equal_to: 0)
    |> validate_number(:selling_price, greater_than_or_equal_to: 0)
    |> validate_number(:stock_quantity, greater_than_or_equal_to: 0)
    |> validate_selling_price_greater_than_cost()
    |> put_slug()
    |> foreign_key_constraint(:category_id)
    |> unique_constraint(:slug)
  end

  @doc """
  Changeset with nested variants and ingredients.
  Used when creating products with variants/ingredients in one operation.
  """
  def changeset_with_associations(product, attrs) do
    product
    |> changeset(attrs)
    |> cast_assoc(:variants, with: &SnackShop.Products.ProductVariant.changeset/2)
    |> cast_assoc(:ingredients, with: &SnackShop.Products.ProductIngredient.changeset/2)
  end

  defp validate_selling_price_greater_than_cost(changeset) do
    cost_price = get_field(changeset, :cost_price)
    selling_price = get_field(changeset, :selling_price)

    if cost_price && selling_price && Decimal.compare(selling_price, cost_price) == :lt do
      add_error(changeset, :selling_price, "must be greater than or equal to cost price")
    else
      changeset
    end
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

  @doc """
  Calculates profit margin percentage.

  ## Examples

      iex> product = %Product{cost_price: Decimal.new("50"), selling_price: Decimal.new("120")}
      iex> Product.profit_margin(product)
      Decimal.new("58.33")
  """
  def profit_margin(%__MODULE__{cost_price: cost, selling_price: selling}) do
    if Decimal.compare(cost, 0) == :gt do
      selling
      |> Decimal.sub(cost)
      |> Decimal.div(cost)
      |> Decimal.mult(100)
      |> Decimal.round(2)
    else
      Decimal.new(0)
    end
  end

  @doc """
  Calculates profit amount per unit.
  """
  def profit_amount(%__MODULE__{cost_price: cost, selling_price: selling}) do
    Decimal.sub(selling, cost)
  end

  @doc """
  Checks if product is in stock.
  """
  def in_stock?(%__MODULE__{stock_quantity: qty, is_available: available}) do
    available && qty > 0
  end

  @doc """
  Checks if product is low on stock (less than 10 units).
  """
  def low_stock?(%__MODULE__{stock_quantity: qty}) do
    qty > 0 && qty < 10
  end
end
