defmodule SnackShopWeb.Admin.OrderController do
  use SnackShopWeb, :controller

  alias SnackShop.Orders

  def index(conn, params) do
    orders =
      case params do
        %{"status" => status} when status != "all" ->
          Orders.list_orders_by_status(status)

        _ ->
          Orders.list_all_orders()
      end

    order_stats = Orders.order_stats()

    render(conn, :index,
      orders: orders,
      order_stats: order_stats,
      filter_status: params["status"] || "all"
    )
  end

  def show(conn, %{"id" => id}) do
    order = Orders.get_order!(id)
    render(conn, :show, order: order)
  end

  def confirm(conn, %{"id" => id}) do
    order = Orders.get_order!(id)

    case Orders.confirm_order(order) do
      {:ok, _order} ->
        conn
        |> put_flash(:info, "Order confirmed successfully")
        |> redirect(to: ~p"/admin/orders/#{id}")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Failed to confirm order")
        |> redirect(to: ~p"/admin/orders/#{id}")
    end
  end

  def update_status(conn, %{"id" => id, "status" => new_status}) do
    order = Orders.get_order!(id)

    case Orders.update_order_status(order, new_status) do
      {:ok, _order} ->
        conn
        |> put_flash(:info, "Order status updated to #{format_status(new_status)}")
        |> redirect(to: ~p"/admin/orders/#{id}")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Failed to update order status")
        |> redirect(to: ~p"/admin/orders/#{id}")
    end
  end

  defp format_status("out_for_delivery"), do: "Out for Delivery"
  defp format_status(status), do: String.capitalize(status)
end
