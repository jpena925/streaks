defmodule StreaksWeb.ErrorJSONTest do
  use StreaksWeb.ConnCase, async: true

  test "renders 404" do
    assert StreaksWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert StreaksWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
