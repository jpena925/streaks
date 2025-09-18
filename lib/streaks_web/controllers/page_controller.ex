defmodule StreaksWeb.PageController do
  use StreaksWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
