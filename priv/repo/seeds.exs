# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     SnackShop.Repo.insert!(%SnackShop.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
defmodule SnackShop.Repo.Seeds do
  @moduledoc """
  Seeds the database with initial data for categories, admin user, and sample products.

  Run with: mix run priv/repo/seeds.exs
  """

  alias SnackShop.Repo
  alias SnackShop.Accounts.User
  alias SnackShop.Products.{Category, Product, ProductVariant, ProductIngredient}

  # Clear existing data (for development only)
  def clear_data do
    Repo.delete_all(ProductIngredient)
    Repo.delete_all(ProductVariant)
    Repo.delete_all(Product)
    Repo.delete_all(Category)
    Repo.delete_all(User)
  end

  # Seed categories
  def seed_categories do
    categories = [
      %{
        name: "Drinks",
        description: "Refreshing beverages and juices",
        slug: "drinks"
      },
      %{
        name: "Snacks",
        description: "Quick bites and treats",
        slug: "snacks"
      },
      %{
        name: "Food",
        description: "Main meals and food items",
        slug: "food"
      }
    ]

    Enum.each(categories, fn cat_attrs ->
      %Category{}
      |> Category.changeset(cat_attrs)
      |> Repo.insert!()
    end)

    IO.puts("✅ Categories seeded successfully")
  end

  # Seed admin user
  def seed_admin_user do
    admin_attrs = %{
      email: "admin@snackshop.com",
      password: "Admin@123456",
      first_name: "Admin",
      last_name: "User",
      phone_number: "+254700000000",
      role: "admin",
      confirmed_at: NaiveDateTime.utc_now()
    }

    %User{}
    |> User.registration_changeset(admin_attrs)
    |> Repo.insert!()

    IO.puts(" Admin user created")
    IO.puts("   Email: admin@snackshop.com")
    IO.puts("   Password: Admin@123456")
  end

  def seed_user do
    admin_attrs = %{
      email: "mken@gmail.com",
      password: "Mken@123456",
      first_name: "Admin",
      last_name: "User",
      role: "customer",
      phone_number: "+254700000000",
      confirmed_at: NaiveDateTime.utc_now()
    }

    %User{}
    |> User.registration_changeset(admin_attrs)
    |> Repo.insert!()

    IO.puts("Admin user created")
    IO.puts("   Email: admin@snackshop.com")
    IO.puts("   Password: Admin@123456")
  end

  # Seed initial products (Week 1)
  def seed_products do
    drinks_category = Repo.get_by!(Category, slug: "drinks")
    snacks_category = Repo.get_by!(Category, slug: "snacks")
    food_category = Repo.get_by!(Category, slug: "food")

    # 1. Blended Juice (Drink with variants)
    blended_juice =
      %Product{}
      |> Product.changeset(%{
        category_id: drinks_category.id,
        name: "Blended Juice",
        description: "Fresh fruit blended juice made daily",
        cost_price: Decimal.new("50.00"),
        selling_price: Decimal.new("120.00"),
        stock_quantity: 50,
        is_available: true,
        slug: "blended-juice"
      })
      |> Repo.insert!()

    # Add size variants for juice
    juice_variants = [
      %{name: "Size", value: "Small (300ml)", price_adjustment: Decimal.new("0.00")},
      %{name: "Size", value: "Medium (500ml)", price_adjustment: Decimal.new("50.00")},
      %{name: "Size", value: "Large (700ml)", price_adjustment: Decimal.new("100.00")}
    ]

    Enum.each(juice_variants, fn variant_attrs ->
      %ProductVariant{}
      |> ProductVariant.changeset(Map.put(variant_attrs, :product_id, blended_juice.id))
      |> Repo.insert!()
    end)

    # 2. Ice-pops (Snack with flavor variants)
    ice_pops =
      %Product{}
      |> Product.changeset(%{
        category_id: snacks_category.id,
        name: "Ice-pops",
        description: "Frozen flavored ice treats",
        cost_price: Decimal.new("10.00"),
        selling_price: Decimal.new("30.00"),
        stock_quantity: 100,
        is_available: true,
        slug: "ice-pops"
      })
      |> Repo.insert!()

    # Add flavor variants for ice-pops
    ice_pop_variants = [
      %{name: "Flavor", value: "Strawberry", price_adjustment: Decimal.new("0.00")},
      %{name: "Flavor", value: "Mango", price_adjustment: Decimal.new("0.00")},
      %{name: "Flavor", value: "Orange", price_adjustment: Decimal.new("0.00")},
      %{name: "Flavor", value: "Mixed Fruit", price_adjustment: Decimal.new("5.00")}
    ]

    Enum.each(ice_pop_variants, fn variant_attrs ->
      %ProductVariant{}
      |> ProductVariant.changeset(Map.put(variant_attrs, :product_id, ice_pops.id))
      |> Repo.insert!()
    end)

    # 3. Mandazi (Food with ingredients)
    mandazi =
      %Product{}
      |> Product.changeset(%{
        category_id: food_category.id,
        name: "Mandazi",
        description: "Traditional East African fried dough",
        cost_price: Decimal.new("5.00"),
        selling_price: Decimal.new("15.00"),
        stock_quantity: 200,
        is_available: true,
        slug: "mandazi"
      })
      |> Repo.insert!()

    # Add ingredients for mandazi
    mandazi_ingredients = [
      "Wheat Flour",
      "Sugar",
      "Coconut Milk",
      "Cardamom",
      "Vegetable Oil"
    ]

    Enum.each(mandazi_ingredients, fn ingredient_name ->
      %ProductIngredient{}
      |> ProductIngredient.changeset(%{
        product_id: mandazi.id,
        name: ingredient_name
      })
      |> Repo.insert!()
    end)

    # 4. Bajia (Food with ingredients)
    bajia =
      %Product{}
      |> Product.changeset(%{
        category_id: food_category.id,
        name: "Bajia",
        description: "Spiced lentil fritters",
        cost_price: Decimal.new("8.00"),
        selling_price: Decimal.new("25.00"),
        stock_quantity: 150,
        is_available: true,
        slug: "bajia"
      })
      |> Repo.insert!()

    # Add ingredients for bajia
    bajia_ingredients = [
      "Lentils (Gram Dal)",
      "Onions",
      "Green Chilies",
      "Coriander",
      "Garlic",
      "Ginger",
      "Curry Leaves",
      "Spices",
      "Vegetable Oil"
    ]

    Enum.each(bajia_ingredients, fn ingredient_name ->
      %ProductIngredient{}
      |> ProductIngredient.changeset(%{
        product_id: bajia.id,
        name: ingredient_name
      })
      |> Repo.insert!()
    end)

    IO.puts(" Products seeded successfully:")
    IO.puts("   - Blended Juice (with size variants)")
    IO.puts("   - Ice-pops (with flavor variants)")
    IO.puts("   - Mandazi (with ingredients)")
    IO.puts("   - Bajia (with ingredients)")
  end

  # Run all seeds
  def run do
    IO.puts(" Starting database seeding...")

    # Uncomment next line in development to reset data
    # clear_data()

    seed_categories()
    seed_admin_user()
    seed_products()

    IO.puts(" Database seeding completed!")
  end
end

# Run the seeds
SnackShop.Repo.Seeds.run()
