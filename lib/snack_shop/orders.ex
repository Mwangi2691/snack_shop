defmodule SnackShop.Orders do
  @moduledoc """
  The Orders context handles order placement and management.

  This includes:
  - Creating orders from cart
  - Order status management
  - Order history
  - Order cancellation
  """

  import Ecto.Query, warn: false
  alias SnackShop.Repo
  alias SnackShop.Orders.{Order, OrderItem}
  alias SnackShop.Cart
  alias SnackShop.Products

  ## Order Creation

  @doc """
  Creates an order from the user's cart.

  This function:
  1. Validates cart has items
  2. Validates stock availability
  3. Creates order and order items
  4. Reduces product stock
  5. Clears the cart

  ## Examples

      iex> create_order_from_cart(user_id, %{
      ...>   delivery_address: "123 Main St",
      ...>   delivery_phone: "+254712345678"
      ...> })
      {:ok, %Order{}}
  """
  def create_order_from_cart(user_id, attrs \\ %{}) do
    # Get cart items
    cart_items = Cart.get_cart_with_details(user_id)

    # Validate cart not empty
    if Enum.empty?(cart_items) do
      {:error, :empty_cart}
    else
      # Validate stock availability
      case Cart.validate_cart_stock(user_id) do
        {:ok, []} ->
          # Calculate total
          total = Cart.calculate_cart_total(user_id)

          # Create order in transaction
          Repo.transaction(fn ->
            # Create order
            order_attrs =
              attrs
              |> Map.put(:user_id, user_id)
              |> Map.put(:total_amount, total)
              |> Map.put(:order_number, Order.generate_order_number())
              |> Map.put(:status, "pending")
              |> Map.put(:payment_status, "pending")

            case create_order(order_attrs) do
              {:ok, order} ->
                # Create order items from cart
                case create_order_items_from_cart(order, cart_items) do
                  {:ok, _order_items} ->
                    # Reduce stock for each product
                    reduce_stock_for_order(cart_items)

                    # Clear cart
                    Cart.clear_cart(user_id)

                    # Return order with items
                    Repo.preload(order, items: [:product, :variant])

                  {:error, reason} ->
                    Repo.rollback(reason)
                end

              {:error, changeset} ->
                Repo.rollback(changeset)
            end
          end)

        {:error, insufficient_items} ->
          {:error, {:insufficient_stock, insufficient_items}}
      end
    end
  end

  defp create_order_items_from_cart(order, cart_items) do
    order_items =
      Enum.map(cart_items, fn cart_item ->
        OrderItem.from_cart_item(cart_item, order.id)
      end)

    # Insert all order items
    case Repo.insert_all(OrderItem, order_items, returning: true) do
      {count, items} when count > 0 -> {:ok, items}
      _ -> {:error, :failed_to_create_order_items}
    end
  end

  defp reduce_stock_for_order(cart_items) do
    Enum.each(cart_items, fn cart_item ->
      product = Products.get_product!(cart_item.product_id)
      Products.reduce_stock(product, cart_item.quantity)
    end)
  end

  @doc """
  Creates an order (low-level function).
  Prefer using `create_order_from_cart/2` for normal checkout flow.

  ## Examples

      iex> create_order(%{
      ...>   user_id: 1,
      ...>   order_number: "ORD-20250129-0001",
      ...>   total_amount: 450
      ...> })
      {:ok, %Order{}}
  """
  def create_order(attrs \\ %{}) do
    %Order{}
    |> Order.changeset(attrs)
    |> Repo.insert()
  end

  ## Order Retrieval

  @doc """
  Lists all orders (admin function).

  ## Examples

      iex> list_all_orders()
      [%Order{}, %Order{}]
  """
  def list_all_orders do
    Order
    |> order_by([o], desc: o.inserted_at)
    |> Repo.all()
    |> Repo.preload([:user, items: [:product, :variant]])
  end

  @doc """
  Lists orders for a specific user.

  ## Examples

      iex> list_user_orders(user_id)
      [%Order{}, %Order{}]
  """
  def list_user_orders(user_id) do
    Order
    |> where([o], o.user_id == ^user_id)
    |> order_by([o], desc: o.inserted_at)
    |> Repo.all()
    |> Repo.preload(items: [:product, :variant])
  end

  @doc """
  Gets a single order by ID.

  ## Examples

      iex> get_order!(1)
      %Order{}
  """
  def get_order!(id) do
    Order
    |> Repo.get!(id)
    |> Repo.preload([:user, items: [:product, :variant]])
  end

  @doc """
  Gets an order by order number.

  ## Examples

      iex> get_order_by_number("ORD-20250129-0001")
      %Order{}
  """
  def get_order_by_number(order_number) do
    Order
    |> Repo.get_by(order_number: order_number)
    |> Repo.preload([:user, items: [:product, :variant]])
  end

  @doc """
  Gets an order by ID for a specific user.
  Returns nil if order doesn't belong to user.

  ## Examples

      iex> get_user_order(1, user_id)
      %Order{}
  """
  def get_user_order(order_id, user_id) do
    Order
    |> where([o], o.id == ^order_id and o.user_id == ^user_id)
    |> Repo.one()
    |> case do
      nil -> nil
      order -> Repo.preload(order, items: [:product, :variant])
    end
  end

  ## Order Status Management

  @doc """
  Updates an order's status.

  ## Examples

      iex> update_order_status(order, "confirmed")
      {:ok, %Order{status: "confirmed"}}
  """
  def update_order_status(%Order{} = order, new_status) do
    order
    |> Order.status_changeset(new_status)
    |> Repo.update()
  end

  @doc """
  Confirms an order (admin action).
  Sets status to "confirmed" and records confirmed_at timestamp.

  ## Examples

      iex> confirm_order(order)
      {:ok, %Order{status: "confirmed"}}
  """
  def confirm_order(%Order{} = order) do
    order
    |> Order.confirm_changeset()
    |> Repo.update()
  end

  @doc """
  Marks an order as preparing.

  ## Examples

      iex> mark_preparing(order)
      {:ok, %Order{status: "preparing"}}
  """
  def mark_preparing(%Order{} = order) do
    update_order_status(order, "preparing")
  end

  @doc """
  Marks an order as out for delivery.

  ## Examples

      iex> mark_out_for_delivery(order)
      {:ok, %Order{status: "out_for_delivery"}}
  """
  def mark_out_for_delivery(%Order{} = order) do
    update_order_status(order, "out_for_delivery")
  end

  @doc """
  Marks an order as delivered.
  Sets status to "delivered", payment_status to "paid", and records delivered_at.

  ## Examples

      iex> mark_delivered(order)
      {:ok, %Order{status: "delivered", payment_status: "paid"}}
  """
  def mark_delivered(%Order{} = order) do
    order
    |> Order.deliver_changeset()
    |> Repo.update()
  end

  @doc """
  Cancels an order.
  Only works if order is "pending" or "confirmed".
  Restores product stock.

  ## Examples

      iex> cancel_order(order)
      {:ok, %Order{status: "cancelled"}}

      iex> cancel_order(delivered_order)
      {:error, :cannot_cancel}
  """
  def cancel_order(%Order{} = order) do
    if Order.cancellable?(order) do
      Repo.transaction(fn ->
        # Restore stock
        order = Repo.preload(order, items: [:product])
        restore_stock_for_order(order.items)

        # Update status
        case update_order_status(order, "cancelled") do
          {:ok, order} -> order
          {:error, changeset} -> Repo.rollback(changeset)
        end
      end)
    else
      {:error, :cannot_cancel}
    end
  end

  defp restore_stock_for_order(order_items) do
    Enum.each(order_items, fn order_item ->
      product = Products.get_product!(order_item.product_id)
      Products.increase_stock(product, order_item.quantity)
    end)
  end

  ## Order Queries & Filters

  @doc """
  Lists orders by status.

  ## Examples

      iex> list_orders_by_status("pending")
      [%Order{status: "pending"}, ...]
  """
  def list_orders_by_status(status) do
    Order
    |> where([o], o.status == ^status)
    |> order_by([o], desc: o.inserted_at)
    |> Repo.all()
    |> Repo.preload([:user, items: [:product, :variant]])
  end

  @doc """
  Lists orders within a date range.

  ## Examples

      iex> list_orders_by_date_range(~D[2025-01-01], ~D[2025-01-31])
      [%Order{}, ...]
  """
  def list_orders_by_date_range(start_date, end_date) do
    start_datetime = DateTime.new!(start_date, ~T[00:00:00])
    end_datetime = DateTime.new!(end_date, ~T[23:59:59])

    Order
    |> where([o], o.inserted_at >= ^start_datetime and o.inserted_at <= ^end_datetime)
    |> order_by([o], desc: o.inserted_at)
    |> Repo.all()
    |> Repo.preload([:user, items: [:product, :variant]])
  end

  @doc """
  Lists recent orders (last N orders).

  ## Examples

      iex> recent_orders(10)
      [%Order{}, ...] # Last 10 orders
  """
  def recent_orders(limit \\ 10) do
    Order
    |> order_by([o], desc: o.inserted_at)
    |> limit(^limit)
    |> Repo.all()
    |> Repo.preload([:user, items: [:product, :variant]])
  end

  ## Order Statistics

  @doc """
  Counts total orders.

  ## Examples

      iex> count_orders()
      156
  """
  def count_orders do
    Repo.aggregate(Order, :count)
  end

  @doc """
  Counts orders by status.

  ## Examples

      iex> count_orders_by_status("pending")
      12
  """
  def count_orders_by_status(status) do
    Order
    |> where([o], o.status == ^status)
    |> Repo.aggregate(:count)
  end

  @doc """
  Calculates total revenue from delivered orders.

  ## Examples

      iex> total_revenue()
      Decimal.new("45000.00")
  """
  def total_revenue do
    Order
    |> where([o], o.status == "delivered")
    |> select([o], sum(o.total_amount))
    |> Repo.one() || Decimal.new("0")
  end

  @doc """
  Calculates revenue for a date range.

  ## Examples

      iex> revenue_for_date_range(~D[2025-01-01], ~D[2025-01-31])
      Decimal.new("12500.00")
  """
  def revenue_for_date_range(start_date, end_date) do
    start_datetime = DateTime.new!(start_date, ~T[00:00:00])
    end_datetime = DateTime.new!(end_date, ~T[23:59:59])

    Order
    |> where([o], o.status == "delivered")
    |> where([o], o.inserted_at >= ^start_datetime and o.inserted_at <= ^end_datetime)
    |> select([o], sum(o.total_amount))
    |> Repo.one() || Decimal.new("0")
  end

  @doc """
  Gets order count statistics by status.

  ## Examples

      iex> order_stats()
      %{
        pending: 5,
        confirmed: 3,
        preparing: 2,
        out_for_delivery: 1,
        delivered: 45,
        cancelled: 2
      }
  """
  def order_stats do
    Order
    |> group_by([o], o.status)
    |> select([o], {o.status, count(o.id)})
    |> Repo.all()
    |> Enum.into(%{}, fn {status, count} -> {String.to_atom(status), count} end)
  end

  ## Changesets

  @doc """
  Returns an order changeset for tracking changes (for forms).
  """
  def change_order(%Order{} = order, attrs \\ %{}) do
    Order.changeset(order, attrs)
  end
end
