defmodule SnackShopWeb.PageController do
  use SnackShopWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
