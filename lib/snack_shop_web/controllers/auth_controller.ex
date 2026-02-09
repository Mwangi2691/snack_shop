defmodule SnackShopWeb.AuthController do
  use SnackShopWeb, :controller
  alias SnackShop.Accounts

  # Registration
  def new_registration(conn, _params) do
    changeset = Accounts.change_registration()
    render(conn, :new_registration, changeset: changeset)
  end

  # def create_registration(conn, %{"user" => user_params}) do
  #   case Accounts.register_user(user_params) do
  #     {:ok, _user} ->
  #       conn
  #       |> put_flash(:info, "Account created successfully! Please log in.")
  #       |> redirect(to: ~p"/products")
  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       render(conn, :new_registration, changeset: changeset)
  #   end
  # end
  def create_registration(conn, %{"user" => user_params}) do
  case Accounts.register_user(user_params) do
    {:ok, user} ->
      conn
      |> put_session(:user_id, user.id)
      |> put_flash(:info, "Account created! You can now place your order.")
      |> redirect(to: ~p"/products")
    {:error, %Ecto.Changeset{} = changeset} ->
      render(conn, :new_registration, changeset: changeset)
  end
end

  # Login
  def new_session(conn, _params), do: render(conn, :new_session)

  # def create_session(conn, %{"session" => %{"email" => email, "password" => password}}) do
  #   case Accounts.authenticate_user(email, password) do
  #     {:ok, user} ->
  #       conn
  #       |> put_session(:user_id, user.id)
  #       |> put_flash(:info, "Welcome back, #{user.first_name}!")
  #       |> redirect_by_role(user)
  #     {:error, :invalid_credentials} ->
  #       conn
  #       |> put_flash(:error, "Invalid email or password")
  #       |> render(:new_session)
  #   end
  # end
  # lib/snack_shop_web/controllers/auth_controller.ex

def create_session(conn, %{"session" => %{"email" => email, "password" => password}}) do
  case Accounts.authenticate_user(email, password) do
    {:ok, user} ->
      conn
      |> put_session(:user_id, user.id)
      |> put_session(:live_socket_id, "users_sessions:#{user.id}") # For LiveView if used
      |> put_flash(:info, "Welcome back, #{user.first_name}!")
      |> redirect_by_role(user) # This handles the 302 redirect

    {:error, :invalid_credentials} ->
      conn
      |> put_flash(:error, "Invalid email or password")
      |> render(:new_session) # This would stay on the page with a 200
  end
end

  def delete_session(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: ~p"/")
  end

  # Google OAuth
  def request_google(conn, _params) do
    client_id = Application.get_env(:snack_shop, :google_client_id)
    redirect_uri = SnackShopWeb.Endpoint.url() <> "/auth/google/callback"

    url = "https://accounts.google.com/o/oauth2/v2/auth?client_id=#{client_id}&redirect_uri=#{redirect_uri}&response_type=code&scope=email%20profile"
    redirect(conn, external: url)
  end

  def callback_google(conn, %{"code" => code}) do
    # Logic to exchange code and get user...
    # Make sure you only have ONE callback_google function!
    # After getting user:
    # redirect_by_role(conn, user)
  end

  # The "Engine" for your Role Redirection
  defp redirect_by_role(conn, user) do
    if user.role == "admin" do
      redirect(conn, to: ~p"/admin")
    else
      redirect(conn, to: ~p"/products")
    end
  end
end
