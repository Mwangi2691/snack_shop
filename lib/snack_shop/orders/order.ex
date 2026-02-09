defmodule SnackShop.Orders.Order do
  @moduledoc """
  Order schema representing customer orders.

  Order Status Flow:
  pending → confirmed → preparing → out_for_delivery → delivered

  Can also be: cancelled
  """
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(pending confirmed preparing out_for_delivery delivered cancelled)
  @payment_methods ~w(cash)
  @payment_statuses ~w(pending paid)

  schema "orders" do
    field :order_number, :string
    field :status, :string, default: "pending"
    field :total_amount, :decimal
    field :payment_method, :string, default: "cash"
    field :payment_status, :string, default: "pending"
    field :delivery_address, :string
    field :delivery_phone, :string
    field :notes, :string
    field :confirmed_at, :naive_datetime
    field :delivered_at, :naive_datetime

    # Associations
    belongs_to :user, SnackShop.Accounts.User
    has_many :items, SnackShop.Orders.OrderItem, on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating orders.
  """
  def changeset(order, attrs) do
    order
    |> cast(attrs, [
      :user_id, :order_number, :status, :total_amount, :payment_method,
      :payment_status, :delivery_address, :delivery_phone, :notes
    ])
    |> validate_required([:user_id, :order_number, :total_amount, :payment_method])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:payment_method, @payment_methods)
    |> validate_inclusion(:payment_status, @payment_statuses)
    |> validate_number(:total_amount, greater_than: 0)
    |> validate_length(:delivery_address, max: 500)
    |> validate_format(:delivery_phone, ~r/^\+?[1-9]\d{1,14}$/,
         message: "must be a valid phone number")
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:order_number)
  end

  @doc """
  Changeset with nested order items.
  """
  def changeset_with_items(order, attrs) do
    order
    |> changeset(attrs)
    |> cast_assoc(:items, with: &SnackShop.Orders.OrderItem.changeset/2)
  end

  @doc """
  Changeset for updating order status.
  """
  def status_changeset(order, new_status) do
    order
    |> change(status: new_status)
    |> validate_inclusion(:status, @statuses)
    |> maybe_set_confirmed_at(new_status)
    |> maybe_set_delivered_at(new_status)
  end

  @doc """
  Changeset for confirming order (admin action).
  """
  def confirm_changeset(order) do
    order
    |> change(
      status: "confirmed",
      confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    )
  end

  @doc """
  Changeset for marking order as delivered.
  """
  def deliver_changeset(order) do
    order
    |> change(
      status: "delivered",
      payment_status: "paid",
      delivered_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    )
  end

  defp maybe_set_confirmed_at(changeset, "confirmed") do
    put_change(changeset, :confirmed_at, NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
  end
  defp maybe_set_confirmed_at(changeset, _), do: changeset

  defp maybe_set_delivered_at(changeset, "delivered") do
    changeset
    |> put_change(:delivered_at, NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
    |> put_change(:payment_status, "paid")
  end
  defp maybe_set_delivered_at(changeset, _), do: changeset

  @doc """
  Generates unique order number.
  Format: ORD-YYYYMMDD-XXXX (e.g., ORD-20250129-0001)
  """
  def generate_order_number do
    date = Date.utc_today() |> Date.to_string() |> String.replace("-", "")
    random = :rand.uniform(9999) |> Integer.to_string() |> String.pad_leading(4, "0")
    "ORD-#{date}-#{random}"
  end

  @doc """
  Returns human-readable status.
  """
  def status_display(status) do
    case status do
      "pending" -> "Pending"
      "confirmed" -> "Confirmed"
      "preparing" -> "Preparing"
      "out_for_delivery" -> "Out for Delivery"
      "delivered" -> "Delivered"
      "cancelled" -> "Cancelled"
      _ -> status
    end
  end

  @doc """
  Checks if order can be cancelled.
  """
  def cancellable?(%__MODULE__{status: status}) when status in ["pending", "confirmed"], do: true
  def cancellable?(_), do: false

  @doc """
  Checks if order is completed.
  """
  def completed?(%__MODULE__{status: "delivered"}), do: true
  def completed?(_), do: false
end
