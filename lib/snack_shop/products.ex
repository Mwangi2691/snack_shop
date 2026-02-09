defmodule SnackShop.Products do
  @moduledoc """
  The Products context handles product catalog management.

  This includes:
  - Product CRUD operations
  - Category management
  - Inventory tracking
  - Product variants and ingredients
  """

  import Ecto.Query, warn: false
  alias SnackShop.Repo
  alias SnackShop.Products.{Category, Product, ProductVariant, ProductIngredient}

  ## Categories

  @doc """
  Lists all categories.

  ## Examples

      iex> list_categories()
      [%Category{}, %Category{}]
  """
  def list_categories do
    Repo.all(Category)
  end

  @doc """
  Gets a single category by ID.
  Raises `Ecto.NoResultsError` if not found.

  ## Examples

      iex> get_category!(1)
      %Category{}
  """
  def get_category!(id), do: Repo.get!(Category, id)

  @doc """
  Gets a category by slug.

  ## Examples

      iex> get_category_by_slug("drinks")
      %Category{slug: "drinks"}
  """
  def get_category_by_slug(slug) do
    Repo.get_by(Category, slug: slug)
  end

  @doc """
  Gets a category with its products preloaded.

  ## Examples

      iex> get_category_with_products!(1)
      %Category{products: [%Product{}, ...]}
  """
  def get_category_with_products!(id) do
    Category
    |> Repo.get!(id)
    |> Repo.preload(products: [:variants, :ingredients])
  end

  @doc """
  Creates a category.

  ## Examples

      iex> create_category(%{name: "Drinks"})
      {:ok, %Category{}}
  """
  def create_category(attrs \\ %{}) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a category.

  ## Examples

      iex> update_category(category, %{name: "Beverages"})
      {:ok, %Category{}}
  """
  def update_category(%Category{} = category, attrs) do
    category
    |> Category.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a category.
  Will fail if category has products (foreign key constraint).

  ## Examples

      iex> delete_category(category)
      {:ok, %Category{}}
  """
  def delete_category(%Category{} = category) do
    Repo.delete(category)
  end

  ## Products

  @doc """
  Lists all products.

  ## Examples

      iex> list_products()
      [%Product{}, %Product{}]
  """
  def list_products do
    Product
    |> order_by([p], [desc: p.inserted_at])
    |> Repo.all()
    |> Repo.preload([:category, :variants, :ingredients])
  end

  @doc """
  Lists only available products (is_available: true, stock > 0).

  ## Examples

      iex> list_available_products()
      [%Product{is_available: true, stock_quantity: 10}, ...]
  """
  def list_available_products do
    Product
    |> where([p], p.is_available == true and p.stock_quantity > 0)
    |> order_by([p], p.name)
    |> Repo.all()
    |> Repo.preload([:category, :variants, :ingredients])
  end

  @doc """
  Lists products by category.

  ## Examples

      iex> list_products_by_category(1)
      [%Product{category_id: 1}, ...]
  """
  def list_products_by_category(category_id) do
    Product
    |> where([p], p.category_id == ^category_id)
    |> where([p], p.is_available == true)
    |> order_by([p], p.name)
    |> Repo.all()
    |> Repo.preload([:category, :variants, :ingredients])
  end

  @doc """
  Lists products by category slug.

  ## Examples

      iex> list_products_by_category_slug("drinks")
      [%Product{}, ...]
  """
  def list_products_by_category_slug(slug) do
    Product
    |> join(:inner, [p], c in Category, on: p.category_id == c.id)
    |> where([p, c], c.slug == ^slug and p.is_available == true)
    |> order_by([p], p.name)
    |> Repo.all()
    |> Repo.preload([:category, :variants, :ingredients])
  end

  @doc """
  Gets a single product by ID.

  ## Examples

      iex> get_product!(1)
      %Product{}
  """
  def get_product!(id) do
    Product
    |> Repo.get!(id)
    |> Repo.preload([:category, :variants, :ingredients])
  end

  @doc """
  Gets a product by slug.

  ## Examples

      iex> get_product_by_slug("blended-juice")
      %Product{slug: "blended-juice"}
  """
  def get_product_by_slug(slug) do
    Product
    |> Repo.get_by(slug: slug)
    |> Repo.preload([:category, :variants, :ingredients])
  end

  @doc """
  Creates a product.

  ## Examples

      iex> create_product(%{
      ...>   name: "Blended Juice",
      ...>   category_id: 1,
      ...>   cost_price: 50,
      ...>   selling_price: 120
      ...> })
      {:ok, %Product{}}
  """
  def create_product(attrs \\ %{}) do
    %Product{}
    |> Product.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a product with variants and ingredients.

  ## Examples

      iex> create_product_with_associations(%{
      ...>   name: "Juice",
      ...>   variants: [%{name: "Size", value: "Small"}],
      ...>   ingredients: [%{name: "Mango"}]
      ...> })
      {:ok, %Product{}}
  """
  def create_product_with_associations(attrs \\ %{}) do
    %Product{}
    |> Product.changeset_with_associations(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a product.

  ## Examples

      iex> update_product(product, %{selling_price: 150})
      {:ok, %Product{}}
  """
  def update_product(%Product{} = product, attrs) do
    product
    |> Product.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a product.
  Will fail if product has order items (foreign key constraint).

  ## Examples

      iex> delete_product(product)
      {:ok, %Product{}}
  """
  def delete_product(%Product{} = product) do
    Repo.delete(product)
  end

  ## Inventory Management

  @doc """
  Updates product stock quantity.

  ## Examples

      iex> update_stock(product, 100)
      {:ok, %Product{stock_quantity: 100}}
  """
  def update_stock(%Product{} = product, quantity) when is_integer(quantity) do
    product
    |> Product.changeset(%{stock_quantity: quantity})
    |> Repo.update()
  end

  @doc """
  Reduces product stock by quantity.
  Returns error if insufficient stock.

  ## Examples

      iex> reduce_stock(product, 5)
      {:ok, %Product{stock_quantity: 45}}

      iex> reduce_stock(product, 100) # Only 50 in stock
      {:error, :insufficient_stock}
  """
  def reduce_stock(%Product{stock_quantity: current_stock} = product, quantity)
      when is_integer(quantity) and quantity > 0 do
    if current_stock >= quantity do
      update_stock(product, current_stock - quantity)
    else
      {:error, :insufficient_stock}
    end
  end

  @doc """
  Increases product stock by quantity.

  ## Examples

      iex> increase_stock(product, 20)
      {:ok, %Product{stock_quantity: 70}}
  """
  def increase_stock(%Product{stock_quantity: current_stock} = product, quantity)
      when is_integer(quantity) and quantity > 0 do
    update_stock(product, current_stock + quantity)
  end

  @doc """
  Lists products with low stock (less than 10 units).

  ## Examples

      iex> low_stock_products()
      [%Product{stock_quantity: 5}, ...]
  """
  def low_stock_products do
    Product
    |> where([p], p.stock_quantity > 0 and p.stock_quantity < 10)
    |> order_by([p], [asc: p.stock_quantity, asc: p.name])
    |> Repo.all()
    |> Repo.preload(:category)
  end

  @doc """
  Lists out of stock products.

  ## Examples

      iex> out_of_stock_products()
      [%Product{stock_quantity: 0}, ...]
  """
  def out_of_stock_products do
    Product
    |> where([p], p.stock_quantity == 0)
    |> order_by([p], p.name)
    |> Repo.all()
    |> Repo.preload(:category)
  end

  ## Product Variants

  @doc """
  Creates a product variant.

  ## Examples

      iex> create_variant(%{
      ...>   product_id: 1,
      ...>   name: "Size",
      ...>   value: "Large"
      ...> })
      {:ok, %ProductVariant{}}
  """
  def create_variant(attrs \\ %{}) do
    %ProductVariant{}
    |> ProductVariant.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a product variant.
  """
  def update_variant(%ProductVariant{} = variant, attrs) do
    variant
    |> ProductVariant.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a product variant.
  """
  def delete_variant(%ProductVariant{} = variant) do
    Repo.delete(variant)
  end

  ## Product Ingredients

  @doc """
  Creates a product ingredient.

  ## Examples

      iex> create_ingredient(%{product_id: 1, name: "Flour"})
      {:ok, %ProductIngredient{}}
  """
  def create_ingredient(attrs \\ %{}) do
    %ProductIngredient{}
    |> ProductIngredient.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a product ingredient.
  """
  def update_ingredient(%ProductIngredient{} = ingredient, attrs) do
    ingredient
    |> ProductIngredient.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a product ingredient.
  """
  def delete_ingredient(%ProductIngredient{} = ingredient) do
    Repo.delete(ingredient)
  end

  ## Queries & Stats

  @doc """
  Counts total products.

  ## Examples

      iex> count_products()
      42
  """
  def count_products do
    Repo.aggregate(Product, :count)
  end

  @doc """
  Counts products by category.

  ## Examples

      iex> count_products_by_category(1)
      15
  """
  def count_products_by_category(category_id) do
    Product
    |> where([p], p.category_id == ^category_id)
    |> Repo.aggregate(:count)
  end

  @doc """
  Searches products by name.

  ## Examples

      iex> search_products("juice")
      [%Product{name: "Blended Juice"}, ...]
  """
  def search_products(query) when is_binary(query) do
    search_term = "%#{query}%"

    Product
    |> where([p], ilike(p.name, ^search_term) or ilike(p.description, ^search_term))
    |> where([p], p.is_available == true)
    |> order_by([p], p.name)
    |> Repo.all()
    |> Repo.preload([:category, :variants, :ingredients])
  end

  ## Changesets for forms

  @doc """
  Returns a product changeset for tracking changes (for forms).
  """
  def change_product(%Product{} = product, attrs \\ %{}) do
    Product.changeset(product, attrs)
  end

  @doc """
  Returns a category changeset for tracking changes (for forms).
  """
  def change_category(%Category{} = category, attrs \\ %{}) do
    Category.changeset(category, attrs)
  end
end
