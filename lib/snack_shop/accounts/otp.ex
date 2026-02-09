defmodule SnackShop.Accounts.OTP do
  @moduledoc """
  OTP (One-Time Password) service using Cachex for temporary storage.

  OTP codes:
  - Are 6 digits
  - Expire after 5 minutes
  - Can only be used once
  """

  @cache_name :otp_cache
  # 5 minutes expiry
  @ttl :timer.minutes(5)

  @doc """
  Generates a 6-digit OTP code.

  ## Examples

      iex> OTP.generate_otp()
      "123456"
  """
  # def generate_otp do
  #   :rand.uniform(999_999)
  #   |> Integer.to_string()
  #   |> String.pad_leading(6, "0")
  # end
  def generate_otp(length \\ 6) do
    # Upper, lower case letters and digits
    chars = Enum.concat([?A..?Z, ?a..?z, ?0..?9])

    1..length
    |> Enum.map(fn _ -> Enum.random(chars) end)
    |> to_string()
  end

  @doc """
  Stores OTP code for a user.
  OTP expires after 5 minutes.

  ## Examples

      iex> OTP.store_otp(user_id, "123456")
      :ok
  """
  def store_otp(user_id, otp_code) do
    key = otp_key(user_id)

    Cachex.put(@cache_name, key, otp_code, ttl: @ttl)
    :ok
  end

  @doc """
  Verifies OTP code for a user.
  Returns :valid, :invalid, or :expired.

  OTP is deleted after verification (can only be used once).

  ## Examples

      iex> OTP.verify_otp(user_id, "123456")
      :valid

      iex> OTP.verify_otp(user_id, "wrong")
      :invalid
  """
  def verify_otp(user_id, provided_code) do
    key = otp_key(user_id)

    case Cachex.get(@cache_name, key) do
      {:ok, nil} ->
        # OTP not found or expired
        :expired

      {:ok, stored_code} when stored_code == provided_code ->
        # Valid OTP - delete it so it can't be reused
        Cachex.del(@cache_name, key)
        :valid

      {:ok, _different_code} ->
        # Invalid OTP
        :invalid

      {:error, _} ->
        :expired
    end
  end

  @doc """
  Deletes OTP for a user.
  Useful for cancelling OTP verification.

  ## Examples

      iex> OTP.delete_otp(user_id)
      :ok
  """
  def delete_otp(user_id) do
    key = otp_key(user_id)
    Cachex.del(@cache_name, key)
    :ok
  end

  @doc """
  Checks if OTP exists for a user.

  ## Examples

      iex> OTP.has_otp?(user_id)
      true
  """
  def has_otp?(user_id) do
    key = otp_key(user_id)

    case Cachex.get(@cache_name, key) do
      {:ok, nil} -> false
      {:ok, _code} -> true
      {:error, _} -> false
    end
  end

  # Private functions

  defp otp_key(user_id), do: "otp:user:#{user_id}"
end
