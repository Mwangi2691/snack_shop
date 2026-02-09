defmodule SnackShopWeb.Router do
  use SnackShopWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SnackShopWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    plug :fetch_cart_info
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Authentication required
  pipeline :require_authenticated_user do
    plug :require_user
  end

  # Admin role required
  pipeline :require_admin do
    plug :require_admin_role
  end

  # lib/snack_shop_web/router.ex

  defp fetch_cart_info(conn, _opts) do
    # Check if we have a current_user (assigned by your existing fetch_current_user plug)
    user = conn.assigns[:current_user]

    if user do
      # User is logged in, get their real data
      items = SnackShop.Cart.get_cart_with_details(user.id)
      total = SnackShop.Cart.calculate_cart_total(user.id)

      conn
      |> assign(:cart_items, items)
      |> assign(:cart_total, total)
    else
      # No user, provide empty defaults so the template doesn't crash
      conn
      |> assign(:cart_items, [])
      |> assign(:cart_total, 0)
    end
  end

  ## Public routes
  scope "/", SnackShopWeb do
    pipe_through :browser

    # Home page
    get "/", PageController, :home

    # Authentication routes
    get "/register", AuthController, :new_registration
    post "/register", AuthController, :create_registration
    get "/login", AuthController, :new_session
    post "/login", AuthController, :create_session
    delete "/logout", AuthController, :delete_session

    # Google OAuth
    get "/auth/google", AuthController, :request_google
    get "/auth/google/callback", AuthController, :callback_google

    # Product browsing (public)
    get "/products", ProductController, :index
    get "/products/:slug", ProductController, :show
    get "/categories/:slug", CategoryController, :show
  end

  ## Authenticated user routes
  scope "/", SnackShopWeb do
    pipe_through [:browser, :require_authenticated_user]

    # Shopping cart
    get "/cart", CartController, :show
    post "/cart/add", CartController, :add_item
    put "/cart/:id", CartController, :update_item
    delete "/cart/:id", CartController, :remove_item
    delete "/cart", CartController, :clear

    # Checkout
    get "/checkout", CheckoutController, :new
    post "/checkout/confirm", CheckoutController, :confirm

    # OTP verification
    get "/checkout/verify-otp", CheckoutController, :verify_otp_form
    post "/checkout/verify-otp", CheckoutController, :verify_otp

    # Orders
    get "/orders", OrderController, :index
    get "/orders/:id", OrderController, :show
    put "/orders/:id/cancel", OrderController, :cancel

    # User profile
    get "/profile", ProfileController, :show
    get "/profile/edit", ProfileController, :edit
    put "/profile", ProfileController, :update
  end

  ## Admin routes
  scope "/admin", SnackShopWeb.Admin, as: :admin do
    pipe_through [:browser, :require_authenticated_user, :require_admin]

    # Dashboard
    get "/dash", DashboardController, :index

    # Product management
    resources "/products", ProductController do
      # Nested routes for variants and ingredients
      resources "/variants", VariantController, only: [:new, :create, :delete]
      resources "/ingredients", IngredientController, only: [:new, :create, :delete]
    end

    # Category management
    resources "/categories", CategoryController

    # Order management
    get "/orders", OrderController, :index
    get "/orders/:id", OrderController, :show
    put "/orders/:id/confirm", OrderController, :confirm
    put "/orders/:id/status", OrderController, :update_status

    # Reports
    get "/reports", ReportController, :index
    get "/reports/profit", ReportController, :profit
    get "/reports/inventory", ReportController, :inventory
  end

  # API routes (for AJAX calls)
  scope "/api", SnackShopWeb.API, as: :api do
    pipe_through :api

    # Cart operations
    post "/cart/add", CartController, :add
    get "/cart/count", CartController, :count
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:snack_shop, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: SnackShopWeb.Telemetry
    end
  end

  ## Plugs

  defp fetch_current_user(conn, _opts) do
    user_id = get_session(conn, :user_id)

    if user_id do
      user = SnackShop.Accounts.get_user(user_id)
      assign(conn, :current_user, user)
    else
      assign(conn, :current_user, nil)
    end
  end

  defp require_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> Phoenix.Controller.put_flash(:error, "You must be logged in to access this page")
      |> Phoenix.Controller.redirect(to: ~p"/login")
      |> halt()
    end
  end

  defp require_admin_role(conn, _opts) do
    user = conn.assigns[:current_user]

    if user && user.role == "admin" do
      conn
    else
      conn
      |> Phoenix.Controller.put_flash(:error, "You must be an admin to access this page")
      |> Phoenix.Controller.redirect(to: ~p"/")
      |> halt()
    end
  end
end
