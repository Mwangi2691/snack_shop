defmodule SnackShopWeb.CheckoutController do
  use SnackShopWeb, :controller

  alias SnackShop.{Cart, Orders}
  alias SnackShop.Accounts.OTP

  def new(conn, _params) do
    user_id = get_session(conn, :user_id)
    user = conn.assigns.current_user

    # Check if cart is empty
    if Cart.cart_empty?(user_id) do
      conn
      |> put_flash(:error, "Your cart is empty")
      |> redirect(to: ~p"/products")
    else
      cart_items = Cart.get_cart_with_details(user_id)
      total = Cart.calculate_cart_total(user_id)

      # Validate stock
      case Cart.validate_cart_stock(user_id) do
        {:ok, []} ->
          render(conn, :new,
            cart_items: cart_items,
            total: total,
            user: user
          )

        {:error, insufficient_items} ->
          conn
          |> put_flash(:error, "Some items in your cart are out of stock")
          |> redirect(to: ~p"/cart")
      end
    end
  end

  def confirm(conn, %{"order" => order_params}) do
    user_id = get_session(conn, :user_id)
    user = conn.assigns.current_user

    # Validate cart is not empty
    if Cart.cart_empty?(user_id) do
      conn
      |> put_flash(:error, "Your cart is empty")
      |> redirect(to: ~p"/products")
    else
      # Generate OTP
      otp_code = OTP.generate_otp()
      OTP.store_otp(user_id, otp_code)

      # Store order params in session for after OTP verification
      conn = put_session(conn, :pending_order, order_params)

      # Send OTP via email
      send_otp_email(user, otp_code)

      conn
      |> put_flash(:info, "OTP sent to your email. Please verify to complete your order.")
      |> redirect(to: ~p"/checkout/verify-otp")
    end
  end

  def verify_otp_form(conn, _params) do
    # Check if there's a pending order
    unless get_session(conn, :pending_order) do
      conn
      |> put_flash(:error, "No pending order found")
      |> redirect(to: ~p"/cart")
    else
      render(conn, :verify_otp)
    end
  end

  def verify_otp(conn, %{"otp" => otp_code}) do
    user_id = get_session(conn, :user_id)
    pending_order = get_session(conn, :pending_order)

    case OTP.verify_otp(user_id, otp_code) do
      :valid ->
        # OTP is valid, create the order
        case Orders.create_order_from_cart(user_id, pending_order) do
          {:ok, order} ->
            # Clear pending order from session
            conn = delete_session(conn, :pending_order)

            # Send order confirmation email
            send_order_confirmation_email(order)

            conn
            |> put_flash(:info, "Order placed successfully! Order ##{order.order_number}")
            |> redirect(to: ~p"/orders/#{order.id}")

          {:error, :empty_cart} ->
            conn
            |> delete_session(:pending_order)
            |> put_flash(:error, "Your cart is empty")
            |> redirect(to: ~p"/products")

          {:error, {:insufficient_stock, items}} ->
            conn
            |> delete_session(:pending_order)
            |> put_flash(:error, "Some items are out of stock: #{format_stock_errors(items)}")
            |> redirect(to: ~p"/cart")

          {:error, _changeset} ->
            conn
            |> put_flash(:error, "Failed to create order. Please try again.")
            |> redirect(to: ~p"/checkout")
        end

      :invalid ->
        conn
        |> put_flash(:error, "Invalid OTP code. Please try again.")
        |> render(:verify_otp)

      :expired ->
        conn
        |> delete_session(:pending_order)
        |> put_flash(:error, "OTP has expired. Please restart checkout.")
        |> redirect(to: ~p"/checkout")
    end
  end

  # Private functions

  defp send_otp_email(user, otp_code) do
    # TODO: Implement email sending
    # For now, log the OTP (in production, send actual email)
    require Logger
    Logger.info("OTP for #{user.email}: #{otp_code}")

    # Example using Swoosh:
    # SnackShop.Mailer.deliver(
    #   SnackShop.Emails.otp_email(user, otp_code)
    # )
  end

  defp send_order_confirmation_email(order) do
    # TODO: Implement order confirmation email
    require Logger
    Logger.info("Order confirmation for order ##{order.order_number}")

    # Example:
    # SnackShop.Mailer.deliver(
    #   SnackShop.Emails.order_confirmation_email(order)
    # )
  end

  defp format_stock_errors(items) do
    items
    |> Enum.map(fn item ->
      "#{item.product} (requested: #{item.requested}, available: #{item.available})"
    end)
    |> Enum.join(", ")
  end
end
