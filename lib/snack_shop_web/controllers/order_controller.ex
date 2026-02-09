defmodule SnackShopWeb.OrderController do
  use SnackShopWeb, :controller

  alias SnackShop.Orders

  def index(conn, _params) do
    user_id = get_session(conn, :user_id)
    orders = Orders.list_user_orders(user_id)

    render(conn, :index, orders: orders)
  end

  def show(conn, %{"id" => id}) do
    user_id = get_session(conn, :user_id)

    case Orders.get_user_order(id, user_id) do
      nil ->
        conn
        |> put_flash(:error, "Order not found")
        |> redirect(to: ~p"/orders")

      order ->
        render(conn, :show, order: order)
    end
  end

  def cancel(conn, %{"id" => id}) do
    user_id = get_session(conn, :user_id)

    case Orders.get_user_order(id, user_id) do
      nil ->
        conn
        |> put_flash(:error, "Order not found")
        |> redirect(to: ~p"/orders")

      order ->
        case Orders.cancel_order(order) do
          {:ok, _cancelled_order} ->
            conn
            |> put_flash(:info, "Order cancelled successfully")
            |> redirect(to: ~p"/orders/#{id}")

          {:error, :cannot_cancel} ->
            conn
            |> put_flash(:error, "This order cannot be cancelled")
            |> redirect(to: ~p"/orders/#{id}")
        end
    end
  end
end
