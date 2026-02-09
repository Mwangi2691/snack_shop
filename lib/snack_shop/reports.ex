defmodule SnackShop.Reports do
  @moduledoc """
  The Reports context handles analytics and reporting.

  This includes:
  - Profit/loss calculations
  - Revenue statistics
  - Top-selling products
  - Stock alerts
  """

  import Ecto.Query, warn: false
  alias SnackShop.Repo
  alias SnackShop.Orders.{Order, OrderItem}
  alias SnackShop.Products.Product

  ## Profit Calculations

  @doc """
  Calculates profit for a date range.

  Returns:
  - total_revenue: Total sales
  - total_cost: Total cost of goods sold
  - total_profit: Revenue - Cost
  - profit_margin: (Profit / Revenue) * 100

  ## Examples

      iex> calculate_profit(~D[2025-01-01], ~D[2025-01-31])
      %{
        total_revenue: Decimal.new("50000.00"),
        total_cost: Decimal.new("25000.00"),
        total_profit: Decimal.new("25000.00"),
        profit_margin: Decimal.new("50.00")
      }
  """
  def calculate_profit(start_date, end_date) do
    start_datetime = DateTime.new!(start_date, ~T[00:00:00])
    end_datetime = DateTime.new!(end_date, ~T[23:59:59])

    # Get all delivered orders in date range
    order_items =
      OrderItem
      |> join(:inner, [oi], o in Order, on: oi.order_id == o.id)
      |> where([oi, o], o.status == "delivered")
      |> where([oi, o], o.inserted_at >= ^start_datetime and o.inserted_at <= ^end_datetime)
      |> preload(:product)
      |> Repo.all()

    # Calculate totals
    {revenue, cost} =
      Enum.reduce(order_items, {Decimal.new("0"), Decimal.new("0")}, fn item,
                                                                        {rev_acc, cost_acc} ->
        revenue = Decimal.add(rev_acc, item.total_price)
        cost_per_unit = item.product.cost_price
        item_cost = Decimal.mult(cost_per_unit, item.quantity)
        cost = Decimal.add(cost_acc, item_cost)
        {revenue, cost}
      end)

    profit = Decimal.sub(revenue, cost)

    profit_margin =
      if Decimal.compare(revenue, 0) == :gt do
        profit
        |> Decimal.div(revenue)
        |> Decimal.mult(100)
        |> Decimal.round(2)
      else
        Decimal.new("0")
      end

    %{
      total_revenue: revenue,
      total_cost: cost,
      total_profit: profit,
      profit_margin: profit_margin,
      order_count: Enum.count(order_items |> Enum.map(& &1.order_id) |> Enum.uniq())
    }
  end

  @doc """
  Calculates daily profit breakdown for a date range.

  ## Examples

      iex> daily_profit_breakdown(~D[2025-01-01], ~D[2025-01-07])
      [
        %{date: ~D[2025-01-01], revenue: ..., profit: ...},
        %{date: ~D[2025-01-02], revenue: ..., profit: ...},
        ...
      ]
  """
  def daily_profit_breakdown(start_date, end_date) do
    start_datetime = DateTime.new!(start_date, ~T[00:00:00])
    end_datetime = DateTime.new!(end_date, ~T[23:59:59])

    # Get all order items with orders
    order_items =
      OrderItem
      |> join(:inner, [oi], o in Order, on: oi.order_id == o.id)
      |> where([oi, o], o.status == "delivered")
      |> where([oi, o], o.inserted_at >= ^start_datetime and o.inserted_at <= ^end_datetime)
      |> select([oi, o], %{
        date: fragment("DATE(?)", o.inserted_at),
        total_price: oi.total_price,
        quantity: oi.quantity,
        product_id: oi.product_id
      })
      |> Repo.all()

    # Group by date
    order_items
    |> Enum.group_by(& &1.date)
    |> Enum.map(fn {date, items} ->
      {revenue, cost} = calculate_revenue_and_cost(items)
      profit = Decimal.sub(revenue, cost)

      %{
        date: date,
        revenue: revenue,
        cost: cost,
        profit: profit,
        order_count: Enum.count(items)
      }
    end)
    |> Enum.sort_by(& &1.date, Date)
  end

  defp calculate_revenue_and_cost(items) do
    Enum.reduce(items, {Decimal.new("0"), Decimal.new("0")}, fn item, {rev_acc, cost_acc} ->
      revenue = Decimal.add(rev_acc, item.total_price)

      # Get product cost price
      product = Repo.get!(Product, item.product_id)
      item_cost = Decimal.mult(product.cost_price, item.quantity)
      cost = Decimal.add(cost_acc, item_cost)

      {revenue, cost}
    end)
  end

  ## Revenue Statistics

  @doc """
  Gets revenue statistics overview.

  Returns today's revenue, this week's revenue, this month's revenue, and all-time revenue.

  ## Examples

      iex> revenue_stats()
      %{
        today: Decimal.new("1250.00"),
        this_week: Decimal.new("8900.00"),
        this_month: Decimal.new("35000.00"),
        all_time: Decimal.new("250000.00")
      }
  """
  def revenue_stats do
    today = Date.utc_today()
    week_start = Date.add(today, -7)
    month_start = Date.beginning_of_month(today)

    %{
      today: revenue_for_date(today),
      this_week: revenue_for_date_range(week_start, today),
      this_month: revenue_for_date_range(month_start, today),
      all_time: all_time_revenue()
    }
  end

  defp revenue_for_date(date) do
    start_datetime = DateTime.new!(date, ~T[00:00:00])
    end_datetime = DateTime.new!(date, ~T[23:59:59])

    Order
    |> where([o], o.status == "delivered")
    |> where([o], o.inserted_at >= ^start_datetime and o.inserted_at <= ^end_datetime)
    |> select([o], sum(o.total_amount))
    |> Repo.one() || Decimal.new("0")
  end

  defp revenue_for_date_range(start_date, end_date) do
    start_datetime = DateTime.new!(start_date, ~T[00:00:00])
    end_datetime = DateTime.new!(end_date, ~T[23:59:59])

    Order
    |> where([o], o.status == "delivered")
    |> where([o], o.inserted_at >= ^start_datetime and o.inserted_at <= ^end_datetime)
    |> select([o], sum(o.total_amount))
    |> Repo.one() || Decimal.new("0")
  end

  defp all_time_revenue do
    Order
    |> where([o], o.status == "delivered")
    |> select([o], sum(o.total_amount))
    |> Repo.one() || Decimal.new("0")
  end

  ## Top Selling Products

  @doc """
  Gets top-selling products for a date range.

  ## Examples

      iex> top_selling_products(~D[2025-01-01], ~D[2025-01-31], 10)
      [
        %{product: "Blended Juice", quantity_sold: 120, revenue: Decimal.new("14400.00")},
        ...
      ]
  """
  def top_selling_products(start_date, end_date, limit \\ 10) do
    start_datetime = DateTime.new!(start_date, ~T[00:00:00])
    end_datetime = DateTime.new!(end_date, ~T[23:59:59])

    OrderItem
    |> join(:inner, [oi], o in Order, on: oi.order_id == o.id)
    |> join(:inner, [oi], p in Product, on: oi.product_id == p.id)
    |> where([oi, o, p], o.status == "delivered")
    |> where([oi, o, p], o.inserted_at >= ^start_datetime and o.inserted_at <= ^end_datetime)
    |> group_by([oi, o, p], [p.id, p.name])
    |> select([oi, o, p], %{
      product_id: p.id,
      product: p.name,
      quantity_sold: sum(oi.quantity),
      revenue: sum(oi.total_price)
    })
    |> order_by([oi, o, p], desc: sum(oi.quantity))
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  Gets top-selling products of all time.

  ## Examples

      iex> top_selling_products_all_time(5)
      [%{product: "Mandazi", quantity_sold: 1500}, ...]
  """
  def top_selling_products_all_time(limit \\ 10) do
    OrderItem
    |> join(:inner, [oi], o in Order, on: oi.order_id == o.id)
    |> join(:inner, [oi], p in Product, on: oi.product_id == p.id)
    |> where([oi, o, p], o.status == "delivered")
    |> group_by([oi, o, p], [p.id, p.name])
    |> select([oi, o, p], %{
      product_id: p.id,
      product: p.name,
      quantity_sold: sum(oi.quantity),
      revenue: sum(oi.total_price)
    })
    |> order_by([oi, o, p], desc: sum(oi.quantity))
    |> limit(^limit)
    |> Repo.all()
  end

  ## Stock Reports

  @doc """
  Gets products with low stock (less than 10 units).

  ## Examples

      iex> low_stock_report()
      [
        %{product: "Ice-pops", category: "Snacks", stock: 5, status: :critical},
        %{product: "Juice", category: "Drinks", stock: 8, status: :low},
        ...
      ]
  """
  def low_stock_report do
    Product
    |> where([p], p.stock_quantity > 0 and p.stock_quantity < 10)
    |> join(:inner, [p], c in assoc(p, :category))
    |> select([p, c], %{
      product_id: p.id,
      product: p.name,
      category: c.name,
      stock: p.stock_quantity,
      status: fragment("CASE WHEN ? < 5 THEN 'critical' ELSE 'low' END", p.stock_quantity)
    })
    |> order_by([p], asc: p.stock_quantity, asc: p.name)
    |> Repo.all()
    |> Enum.map(fn report ->
      %{report | status: String.to_atom(report.status)}
    end)
  end

  @doc """
  Gets products that are out of stock.

  ## Examples

      iex> out_of_stock_report()
      [%{product: "Bajia", category: "Food", last_sold: ~D[2025-01-28]}, ...]
  """
  def out_of_stock_report do
    Product
    |> where([p], p.stock_quantity == 0)
    |> join(:inner, [p], c in assoc(p, :category))
    |> select([p, c], %{
      product_id: p.id,
      product: p.name,
      category: c.name,
      stock: p.stock_quantity
    })
    |> order_by([p], p.name)
    |> Repo.all()
  end

  ## Dashboard Statistics

  @doc """
  Gets comprehensive dashboard statistics.

  Returns:
  - Total orders (all statuses)
  - Pending orders
  - Today's revenue
  - Low stock count

  ## Examples

      iex> dashboard_stats()
      %{
        total_orders: 156,
        pending_orders: 5,
        todays_revenue: Decimal.new("1250.00"),
        low_stock_products: 3
      }
  """
  def dashboard_stats do
    %{
      total_orders: count_all_orders(),
      pending_orders: count_pending_orders(),
      todays_revenue: revenue_for_date(Date.utc_today()),
      low_stock_products: count_low_stock_products(),
      out_of_stock_products: count_out_of_stock_products()
    }
  end

  defp count_all_orders do
    Repo.aggregate(Order, :count)
  end

  defp count_pending_orders do
    Order
    |> where([o], o.status == "pending")
    |> Repo.aggregate(:count)
  end

  defp count_low_stock_products do
    Product
    |> where([p], p.stock_quantity > 0 and p.stock_quantity < 10)
    |> Repo.aggregate(:count)
  end

  defp count_out_of_stock_products do
    Product
    |> where([p], p.stock_quantity == 0)
    |> Repo.aggregate(:count)
  end
end
