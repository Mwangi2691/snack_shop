defmodule SnackShopWeb.Admin.ProductController do
  use SnackShopWeb, :controller

  alias SnackShop.Products
  alias SnackShop.Products.Product

  def index(conn, params) do
    products =
      case params do
        %{"category_id" => category_id} ->
          Products.list_products_by_category(category_id)

        _ ->
          Products.list_products()
      end

    categories = Products.list_categories()

    render(conn, :index,
      products: products,
      categories: categories
    )
  end

  def new(conn, _params) do
    changeset = Products.change_product(%Product{})
    categories = Products.list_categories()

    render(conn, :new,
      changeset: changeset,
      categories: categories
    )
  end

  def create(conn, %{"product" => product_params}) do
    case Products.create_product(product_params) do
      {:ok, product} ->
        conn
        |> put_flash(:info, "Product created successfully")
        |> redirect(to: ~p"/admin/products/#{product.id}")

      {:error, %Ecto.Changeset{} = changeset} ->
        categories = Products.list_categories()

        render(conn, :new,
          changeset: changeset,
          categories: categories
        )
    end
  end

  def show(conn, %{"id" => id}) do
    product = Products.get_product!(id)
    render(conn, :show, product: product)
  end

  def edit(conn, %{"id" => id}) do
    product = Products.get_product!(id)
    changeset = Products.change_product(product)
    categories = Products.list_categories()

    render(conn, :edit,
      product: product,
      changeset: changeset,
      categories: categories
    )
  end

  def update(conn, %{"id" => id, "product" => product_params}) do
    product = Products.get_product!(id)

    case Products.update_product(product, product_params) do
      {:ok, product} ->
        conn
        |> put_flash(:info, "Product updated successfully")
        |> redirect(to: ~p"/admin/products/#{product.id}")

      {:error, %Ecto.Changeset{} = changeset} ->
        categories = Products.list_categories()

        render(conn, :edit,
          product: product,
          changeset: changeset,
          categories: categories
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    product = Products.get_product!(id)

    case Products.delete_product(product) do
      {:ok, _product} ->
        conn
        |> put_flash(:info, "Product deleted successfully")
        |> redirect(to: ~p"/admin/products")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Cannot delete product (may have associated orders)")
        |> redirect(to: ~p"/admin/products/#{id}")
    end
  end
end
