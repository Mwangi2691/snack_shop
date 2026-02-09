defmodule SnackShop.Accounts.User do
  @moduledoc """
  User schema for both customers and admins.

  Supports:
  - Email/password authentication
  - Google OAuth (via google_id)
  - Role-based access control
  """
  use Ecto.Schema
  import Ecto.Changeset

  @roles ~w(admin customer)
  @email_regex ~r/^[^\s]+@[^\s]+\.[^\s]+$/

  schema "users" do
    field :email, :string
    field :password_hash, :string
    field :first_name, :string
    field :last_name, :string
    field :phone_number, :string
    field :google_id, :string
    field :role, :string, default: "customer"
    field :confirmed_at, :naive_datetime

    # Virtual fields
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true

    # Associations
    has_many :orders, SnackShop.Orders.Order
    has_many :cart_items, SnackShop.Cart.CartItem

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for user registration with email/password.

  ## Examples

      iex> changeset = User.registration_changeset(%User{}, %{
      ...>   email: "user@example.com",
      ...>   password: "SecurePass123!",
      ...>   first_name: "John",
      ...>   last_name: "Doe",
      ...>   phone_number: "+254712345678"
      ...> })
      iex> changeset.valid?
      true
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :password_confirmation, :first_name, :last_name, :phone_number, :role])
    |> validate_required([:email, :password, :first_name, :last_name, :phone_number])
    |> validate_email()
    |> validate_password()
    |> validate_phone_number()
    |> validate_inclusion(:role, @roles)
    |> unique_constraint(:email, message: "Email already registered")
    |> put_password_hash()
  end

  @doc """
  Changeset for Google OAuth registration.
  No password required since authentication is via Google.
  """
  def google_registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :first_name, :last_name, :phone_number, :google_id, :role])
    |> validate_required([:email, :first_name, :last_name, :phone_number, :google_id])
    |> validate_email()
    |> validate_phone_number()
    |> validate_inclusion(:role, @roles)
    |> unique_constraint(:email, message: "Email already registered")
    |> unique_constraint(:google_id)
    |> put_change(:confirmed_at, NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
  end

  @doc """
  Changeset for updating user profile.
  Password and email cannot be changed here.
  """
  def update_changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name, :phone_number])
    |> validate_required([:first_name, :last_name, :phone_number])
    |> validate_phone_number()
  end

  @doc """
  Changeset for email confirmation.
  """
  def confirm_changeset(user) do
    change(user, confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
  end

  # Private functions

  defp validate_email(changeset) do
    changeset
    |> validate_format(:email, @email_regex, message: "must be a valid email address")
    |> validate_length(:email, max: 255)
    |> update_change(:email, &String.downcase/1)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 8, message: "must be at least 8 characters")
    |> validate_length(:password, max: 80, message: "must be at most 80 characters")
    |> validate_format(:password, ~r/[a-z]/, message: "must contain at least one lowercase letter")
    |> validate_format(:password, ~r/[A-Z]/, message: "must contain at least one uppercase letter")
    |> validate_format(:password, ~r/[0-9]/, message: "must contain at least one number")
    |> validate_confirmation(:password, message: "passwords do not match")
  end

  defp validate_phone_number(changeset) do
    changeset
    |> validate_format(:phone_number, ~r/^\+?[1-9]\d{1,14}$/,
         message: "must be a valid phone number (E.164 format)")
  end

  defp put_password_hash(changeset) do
    case get_change(changeset, :password) do
      nil ->
        changeset
      password ->
        changeset
        |> put_change(:password_hash, Bcrypt.hash_pwd_salt(password))
        |> delete_change(:password)
        |> delete_change(:password_confirmation)
    end
  end

  @doc """
  Returns full name of the user.
  """
  def full_name(%__MODULE__{first_name: first, last_name: last}) do
    "#{first} #{last}"
  end

  @doc """
  Checks if user is an admin.
  """
  def admin?(%__MODULE__{role: "admin"}), do: true
  def admin?(_), do: false

  @doc """
  Checks if user email is confirmed.
  """
  def confirmed?(%__MODULE__{confirmed_at: nil}), do: false
  def confirmed?(%__MODULE__{confirmed_at: _}), do: true
end
