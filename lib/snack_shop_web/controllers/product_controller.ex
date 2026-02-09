defmodule SnackShopWeb.ProductController do
  use SnackShopWeb, :controller

  alias SnackShop.Products

  def index(conn, params) do
    products =
      case params do
        %{"search" => query} when query != "" ->
          Products.search_products(query)

        %{"category" => slug} ->
          Products.list_products_by_category_slug(slug)

        _ ->
          Products.list_available_products()
      end

    categories = Products.list_categories()

    render(conn, :index,
      products: products,
      categories: categories,
      search_query: params["search"]
    )
  end

  def show(conn, %{"slug" => slug}) do
    case Products.get_product_by_slug(slug) do
      nil ->
        conn
        |> put_flash(:error, "Product not found")
        |> redirect(to: ~p"/products")

      product ->
        # Check if user is logged in for cart functionality
        user_id = get_session(conn, :user_id)

        render(conn, :show,
          product: product,
          user_id: user_id
        )
    end
  end
end
