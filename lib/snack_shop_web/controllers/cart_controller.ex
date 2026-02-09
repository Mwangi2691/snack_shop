defmodule SnackShopWeb.CartController do
  use SnackShopWeb, :controller

  alias SnackShop.{Cart, Products}

  def show(conn, _params) do
    user_id = get_session(conn, :user_id)
    cart_items = Cart.get_cart_with_details(user_id)
    total = Cart.calculate_cart_total(user_id)

    # Validate stock availability
    {stock_valid, stock_errors} =
      case Cart.validate_cart_stock(user_id) do
        {:ok, []} -> {true, []}
        {:error, items} -> {false, items}
      end

    render(conn, :show,
      cart_items: cart_items,
      total: total,
      stock_valid: stock_valid,
      stock_errors: stock_errors
    )
  end

  def add_item(conn, %{"product_id" => product_id} = params) do
    user_id = get_session(conn, :user_id)

    # Get product to verify it exists and is available
    product = Products.get_product!(product_id)

    unless product.is_available && product.stock_quantity > 0 do
      conn
      |> put_flash(:error, "This product is currently unavailable")
      |> redirect(to: ~p"/products")
    else
      cart_attrs = %{
        user_id: user_id,
        product_id: product_id,
        variant_id: params["variant_id"],
        quantity: String.to_integer(params["quantity"] || "1")
      }

      case Cart.add_to_cart(cart_attrs) do
        {:ok, _cart_item} ->
          conn
          |> put_flash(:info, "#{product.name} added to cart")
          |> redirect(to: params["redirect_to"] || ~p"/cart")

        {:error, _changeset} ->
          conn
          |> put_flash(:error, "Failed to add item to cart")
          |> redirect(to: ~p"/products/#{product.slug}")
      end
    end
  end

  def update_item(conn, %{"id" => id, "quantity" => quantity}) do
    user_id = get_session(conn, :user_id)
    cart_item = Cart.get_cart_item!(id)

    # Verify cart item belongs to current user
    if cart_item.user_id != user_id do
      conn
      |> put_flash(:error, "Unauthorized")
      |> redirect(to: ~p"/cart")
    else
      quantity = String.to_integer(quantity)

      case Cart.update_quantity(cart_item, quantity) do
        {:ok, _updated_item} ->
          conn
          |> put_flash(:info, "Cart updated")
          |> redirect(to: ~p"/cart")

        {:error, _changeset} ->
          conn
          |> put_flash(:error, "Failed to update quantity")
          |> redirect(to: ~p"/cart")
      end
    end
  end

  def remove_item(conn, %{"id" => id}) do
    user_id = get_session(conn, :user_id)

    case Cart.remove_cart_item(id, user_id) do
      {:ok, _cart_item} ->
        conn
        |> put_flash(:info, "Item removed from cart")
        |> redirect(to: ~p"/cart")

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Item not found")
        |> redirect(to: ~p"/cart")
    end
  end

  def clear(conn, _params) do
    user_id = get_session(conn, :user_id)
    Cart.clear_cart(user_id)

    conn
    |> put_flash(:info, "Cart cleared")
    |> redirect(to: ~p"/cart")
  end
end
