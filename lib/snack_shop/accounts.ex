defmodule SnackShop.Accounts do
  @moduledoc """
  The Accounts context handles user authentication and management.

  This includes:
  - User registration (email/password and Google OAuth)
  - User authentication
  - Profile management
  - Email confirmation
  """

  import Ecto.Query, warn: false
  alias SnackShop.Repo
  alias SnackShop.Accounts.User

  ## User Registration

  @spec register_user(
          :invalid
          | %{optional(:__struct__) => none(), optional(atom() | binary()) => any()}
        ) :: any()
  @doc """
  Registers a new user with email and password.

  ## Examples

      iex> register_user(%{email: "user@example.com", password: "SecurePass123!"})
      {:ok, %User{}}

      iex> register_user(%{email: "invalid"})
      {:error, %Ecto.Changeset{}}
  """
  def register_user(attrs \\ %{}) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Registers a new user via Google OAuth.
  No password required.

  ## Examples

      iex> register_google_user(%{
      ...>   email: "user@gmail.com",
      ...>   google_id: "12345",
      ...>   first_name: "John",
      ...>   last_name: "Doe"
      ...> })
      {:ok, %User{}}
  """
  def register_google_user(attrs \\ %{}) do
    %User{}
    |> User.google_registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets or creates a user from Google OAuth data.
  Used in OAuth callback.

  ## Examples

      iex> get_or_create_google_user(%{email: "user@gmail.com", google_id: "123"})
      {:ok, %User{}}
  """
  def get_or_create_google_user(attrs) do
    case get_user_by_google_id(attrs[:google_id]) do
      nil -> register_google_user(attrs)
      user -> {:ok, user}
    end
  end

  ## User Retrieval

  @doc """
  Gets a single user by ID.
  Raises `Ecto.NoResultsError` if user not found.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)
  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Gets a user by ID, returns nil if not found.

  ## Examples

      iex> get_user(123)
      %User{}

      iex> get_user(999)
      nil
  """
  def get_user(id), do: Repo.get(User, id)

  @doc """
  Gets a user by email address.

  ## Examples

      iex> get_user_by_email("user@example.com")
      %User{}

      iex> get_user_by_email("nonexistent@example.com")
      nil
  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: String.downcase(email))
  end

  @doc """
  Gets a user by Google ID.
  """
  def get_user_by_google_id(google_id) when is_binary(google_id) do
    Repo.get_by(User, google_id: google_id)
  end

  @doc """
  Lists all users.
  Admin function only.

  ## Examples

      iex> list_users()
      [%User{}, %User{}]
  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Lists users with optional filters.

  ## Examples

      iex> list_users(%{role: "customer"})
      [%User{role: "customer"}, ...]

      iex> list_users(%{confirmed: true})
      [%User{confirmed_at: ~N[...]}, ...]
  """
  def list_users(filters) when is_map(filters) do
    User
    |> apply_user_filters(filters)
    |> Repo.all()
  end

  defp apply_user_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:role, role}, query ->
        where(query, [u], u.role == ^role)

      {:confirmed, true}, query ->
        where(query, [u], not is_nil(u.confirmed_at))

      {:confirmed, false}, query ->
        where(query, [u], is_nil(u.confirmed_at))

      _, query ->
        query
    end)
  end

  ## Authentication

  @doc """
  Authenticates a user with email and password.
  Returns {:ok, user} if credentials are valid.
  Returns {:error, :invalid_credentials} otherwise.

  ## Examples

      iex> authenticate_user("user@example.com", "correct_password")
      {:ok, %User{}}

      iex> authenticate_user("user@example.com", "wrong_password")
      {:error, :invalid_credentials}
  """
  def authenticate_user(email, password)
      when is_binary(email) and is_binary(password) do
    user = get_user_by_email(email)

    cond do
      user && user.password_hash && Bcrypt.verify_pass(password, user.password_hash) ->
        {:ok, user}

      user ->
        # Prevent timing attacks
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}

      true ->
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}
    end
  end

  @doc """
  Verifies if a password is correct for a user.

  ## Examples

      iex> verify_password(user, "correct_password")
      true

      iex> verify_password(user, "wrong_password")
      false
  """
  def verify_password(%User{password_hash: hash}, password)
      when is_binary(hash) and is_binary(password) do
    Bcrypt.verify_pass(password, hash)
  end

  def verify_password(_, _), do: false

  ## User Updates

  @doc """
  Updates a user's profile.

  ## Examples

      iex> update_user(user, %{first_name: "Jane"})
      {:ok, %User{}}

      iex> update_user(user, %{first_name: ""})
      {:error, %Ecto.Changeset{}}
  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Confirms a user's email address.

  ## Examples

      iex> confirm_user_email(user)
      {:ok, %User{confirmed_at: ~N[...]}}
  """
  def confirm_user_email(%User{} = user) do
    user
    |> User.confirm_changeset()
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}
  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  ## User Queries

  @doc """
  Returns the count of total users.

  ## Examples

      iex> count_users()
      42
  """
  def count_users do
    Repo.aggregate(User, :count)
  end

  @doc """
  Returns the count of users by role.

  ## Examples

      iex> count_users_by_role("customer")
      38
  """
  def count_users_by_role(role) do
    User
    |> where([u], u.role == ^role)
    |> Repo.aggregate(:count)
  end

  @doc """
  Checks if an email is already taken.

  ## Examples

      iex> email_taken?("existing@example.com")
      true

      iex> email_taken?("new@example.com")
      false
  """
  def email_taken?(email) when is_binary(email) do
    User
    |> where([u], u.email == ^String.downcase(email))
    |> Repo.exists?()
  end

  ## Changesets for forms

  @doc """
  Returns a user changeset for tracking user changes (for forms).

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}
  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.update_changeset(user, attrs)
  end

  @doc """
  Returns a changeset for user registration (for forms).

  ## Examples

      iex> change_registration(%User{})
      %Ecto.Changeset{data: %User{}}
  """
  def change_registration(%User{} = user \\ %User{}, attrs \\ %{}) do
    User.registration_changeset(user, attrs)
  end
end
