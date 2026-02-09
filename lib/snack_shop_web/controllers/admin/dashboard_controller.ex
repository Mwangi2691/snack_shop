defmodule SnackShopWeb.Admin.DashboardController do
  use SnackShopWeb, :controller

  alias SnackShop.{Orders, Products, Reports}

  def index(conn, _params) do
    # Get dashboard statistics
    stats = Reports.dashboard_stats()
    revenue_stats = Reports.revenue_stats()

    # Get recent orders
    recent_orders = Orders.recent_orders(10)

    # Get pending orders count
    pending_count = Orders.count_orders_by_status("pending")

    # Get low stock products
    low_stock = Reports.low_stock_report()

    # Get top selling products (last 30 days)
    end_date = Date.utc_today()
    start_date = Date.add(end_date, -30)
    top_products = Reports.top_selling_products(start_date, end_date, 5)

    # Order status breakdown
    order_stats = Orders.order_stats()

    render(conn, :index,
      stats: stats,
      revenue_stats: revenue_stats,
      recent_orders: recent_orders,
      pending_count: pending_count,
      low_stock: low_stock,
      top_products: top_products,
      order_stats: order_stats
    )
  end
end
