defmodule SnackShopWeb.Admin.ReportController do
  use SnackShopWeb, :controller

  alias SnackShop.Reports

  def index(conn, _params) do
    # Default to last 30 days
    end_date = Date.utc_today()
    start_date = Date.add(end_date, -30)

    profit_data = Reports.calculate_profit(start_date, end_date)
    daily_breakdown = Reports.daily_profit_breakdown(start_date, end_date)
    top_products = Reports.top_selling_products(start_date, end_date, 10)

    render(conn, :index,
      start_date: start_date,
      end_date: end_date,
      profit_data: profit_data,
      daily_breakdown: daily_breakdown,
      top_products: top_products
    )
  end

  def profit(conn, params) do
    # Custom date range
    start_date = parse_date(params["start_date"]) || Date.add(Date.utc_today(), -30)
    end_date = parse_date(params["end_date"]) || Date.utc_today()

    # Ensure start_date is before end_date
    {start_date, end_date} =
      if Date.compare(start_date, end_date) == :gt do
        {end_date, start_date}
      else
        {start_date, end_date}
      end

    profit_data = Reports.calculate_profit(start_date, end_date)
    daily_breakdown = Reports.daily_profit_breakdown(start_date, end_date)
    top_products = Reports.top_selling_products(start_date, end_date, 10)

    render(conn, :profit,
      start_date: start_date,
      end_date: end_date,
      profit_data: profit_data,
      daily_breakdown: daily_breakdown,
      top_products: top_products
    )
  end

  def inventory(conn, _params) do
    low_stock = Reports.low_stock_report()
    out_of_stock = Reports.out_of_stock_report()

    render(conn, :inventory,
      low_stock: low_stock,
      out_of_stock: out_of_stock
    )
  end

  # Private functions

  defp parse_date(nil), do: nil

  defp parse_date(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      {:error, _} -> nil
    end
  end
end
