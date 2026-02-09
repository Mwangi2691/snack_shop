defmodule SnackShop.Cart do
  @moduledoc """
  The Cart context handles shopping cart operations.

  This includes:
  - Adding items to cart
  - Updating quantities
  - Removing items
  - Calculating totals
  """

  import Ecto.Query, warn: false
  alias SnackShop.Repo
  alias SnackShop.Cart.CartItem
  alias SnackShop.Products
  # alias SnackShop.Products.Product

  ## Cart Retrieval

  @doc """
  Gets all cart items for a user.

  ## Examples

      iex> get_cart(user_id)
      [%CartItem{}, %CartItem{}]
  """
  def get_cart(user_id) do
    CartItem
    |> where([c], c.user_id == ^user_id)
    |> order_by([c], desc: c.inserted_at)
    |> Repo.all()
    |> Repo.preload([:product, :variant])
  end

  @doc """
  Gets a cart with product details preloaded.

  ## Examples

      iex> get_cart_with_details(user_id)
      [%CartItem{product: %Product{}, variant: %ProductVariant{}}, ...]
  """
  def get_cart_with_details(user_id) do
    CartItem
    |> where([c], c.user_id == ^user_id)
    |> order_by([c], desc: c.inserted_at)
    |> Repo.all()
    |> Repo.preload(product: [:category, :variants], variant: [])
  end

  @doc """
  Gets a single cart item.
  """
  def get_cart_item!(id) do
    CartItem
    |> Repo.get!(id)
    |> Repo.preload([:product, :variant])
  end

  @doc """
  Finds a cart item by user, product, and variant.

  ## Examples

      iex> find_cart_item(user_id, product_id, variant_id)
      %CartItem{}

      iex> find_cart_item(user_id, product_id, nil)
      nil
  """
  # def find_cart_item(user_id, product_id, variant_id \\ nil) do
  #   CartItem
  #   |> where([c], c.user_id == ^user_id)
  #   |> where([c], c.product_id == ^product_id)
  #   |> where([c], c.variant_id == ^variant_id or (is_nil(c.variant_id) and is_nil(^variant_id)))
  #   |> Repo.one()
  # end
  def find_cart_item(user_id, product_id, variant_id \\ nil) do
    query =
      CartItem
      |> where([c], c.user_id == ^user_id)
      |> where([c], c.product_id == ^product_id)

    query =
      if is_nil(variant_id) do
        where(query, [c], is_nil(c.variant_id))
      else
        where(query, [c], c.variant_id == ^variant_id)
      end

    Repo.one(query)
  end

  ## Cart Operations

  @doc """
  Adds a product to the cart.
  If item already exists, increments quantity.

  ## Examples

      iex> add_to_cart(%{
      ...>   user_id: 1,
      ...>   product_id: 5,
      ...>   variant_id: 2,
      ...>   quantity: 2
      ...> })
      {:ok, %CartItem{}}
  """
  def add_to_cart(attrs \\ %{}) do
    user_id = attrs[:user_id] || attrs["user_id"]
    product_id = attrs[:product_id] || attrs["product_id"]
    variant_id = attrs[:variant_id] || attrs["variant_id"]
    quantity = attrs[:quantity] || attrs["quantity"] || 1

    # Check if item already in cart
    case find_cart_item(user_id, product_id, variant_id) do
      nil ->
        # Create new cart item
        %CartItem{}
        |> CartItem.changeset(attrs)
        |> Repo.insert()

      existing_item ->
        # Update quantity of existing item
        update_quantity(existing_item, existing_item.quantity + quantity)
    end
  end

  @doc """
  Updates the quantity of a cart item.

  ## Examples

      iex> update_quantity(cart_item, 5)
      {:ok, %CartItem{quantity: 5}}

      iex> update_quantity(cart_item, 0)
      {:error, %Ecto.Changeset{}}
  """
  def update_quantity(%CartItem{} = cart_item, new_quantity) do
    cart_item
    |> CartItem.changeset(%{quantity: new_quantity})
    |> Repo.update()
  end

  @doc """
  Updates a cart item.

  ## Examples

      iex> update_cart_item(cart_item, %{quantity: 3})
      {:ok, %CartItem{}}
  """
  def update_cart_item(%CartItem{} = cart_item, attrs) do
    cart_item
    |> CartItem.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Removes an item from the cart.

  ## Examples

      iex> remove_from_cart(cart_item)
      {:ok, %CartItem{}}
  """
  def remove_from_cart(%CartItem{} = cart_item) do
    Repo.delete(cart_item)
  end

  @doc """
  Removes a cart item by ID.

  ## Examples

      iex> remove_cart_item(1, user_id)
      {:ok, %CartItem{}}
  """
  def remove_cart_item(cart_item_id, user_id) do
    CartItem
    |> where([c], c.id == ^cart_item_id and c.user_id == ^user_id)
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      cart_item -> Repo.delete(cart_item)
    end
  end

  @doc """
  Clears all items from a user's cart.
  Used after successful checkout.

  ## Examples

      iex> clear_cart(user_id)
      {5, nil} # 5 items deleted
  """
  def clear_cart(user_id) do
    CartItem
    |> where([c], c.user_id == ^user_id)
    |> Repo.delete_all()
  end

  ## Cart Calculations

  @doc """
  Calculates the total price of all items in the cart.

  ## Examples

      iex> calculate_cart_total(user_id)
      Decimal.new("450.00")
  """
  def calculate_cart_total(user_id) do
    cart_items = get_cart_with_details(user_id)

    cart_items
    |> Enum.reduce(Decimal.new("0"), fn item, acc ->
      Decimal.add(acc, CartItem.subtotal(item))
    end)
  end

  @doc """
  Counts the number of items in the cart.

  ## Examples

      iex> count_cart_items(user_id)
      5
  """
  def count_cart_items(user_id) do
    CartItem
    |> where([c], c.user_id == ^user_id)
    |> Repo.aggregate(:count)
  end

  @doc """
  Counts the total quantity of all items in cart.

  ## Examples

      iex> count_cart_quantity(user_id)
      12 # 3 items with qty: 2, 5, 5
  """
  def count_cart_quantity(user_id) do
    CartItem
    |> where([c], c.user_id == ^user_id)
    |> select([c], sum(c.quantity))
    |> Repo.one() || 0
  end

  @doc """
  Checks if cart is empty.

  ## Examples

      iex> cart_empty?(user_id)
      false
  """
  def cart_empty?(user_id) do
    count_cart_items(user_id) == 0
  end

  ## Validation

  @doc """
  Validates that all cart items have sufficient stock.
  Returns list of items with insufficient stock.

  ## Examples

      iex> validate_cart_stock(user_id)
      {:ok, []} # All items in stock

      iex> validate_cart_stock(user_id)
      {:error, [%{product: "Juice", requested: 5, available: 2}]}
  """
  def validate_cart_stock(user_id) do
    cart_items = get_cart_with_details(user_id)

    insufficient_stock =
      Enum.reduce(cart_items, [], fn item, acc ->
        product = Products.get_product!(item.product_id)

        if product.stock_quantity < item.quantity do
          [
            %{
              product: product.name,
              requested: item.quantity,
              available: product.stock_quantity
            }
            | acc
          ]
        else
          acc
        end
      end)

    case insufficient_stock do
      [] -> {:ok, []}
      items -> {:error, items}
    end
  end

  @doc """
  Validates that all cart products are still available.
  Returns list of unavailable products.

  ## Examples

      iex> validate_cart_availability(user_id)
      {:ok, []}
  """
  def validate_cart_availability(user_id) do
    cart_items = get_cart_with_details(user_id)

    unavailable =
      Enum.reduce(cart_items, [], fn item, acc ->
        product = item.product

        if not product.is_available do
          [product.name | acc]
        else
          acc
        end
      end)

    case unavailable do
      [] -> {:ok, []}
      products -> {:error, products}
    end
  end

  ## Changesets

  @doc """
  Returns a cart item changeset for tracking changes (for forms).
  """
  def change_cart_item(%CartItem{} = cart_item, attrs \\ %{}) do
    CartItem.changeset(cart_item, attrs)
  end
end
