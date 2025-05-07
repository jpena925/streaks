defmodule StreaksWeb.StreakLiveTest do
  use StreaksWeb.ConnCase

  import Phoenix.LiveViewTest
  import Streaks.HabitsFixtures

  @create_attrs %{name: "some name", year: 42, days: %{}}
  @update_attrs %{name: "some updated name", year: 43, days: %{}}
  @invalid_attrs %{name: nil, year: nil, days: nil}

  defp create_streak(_) do
    streak = streak_fixture()
    %{streak: streak}
  end

  describe "Index" do
    setup [:create_streak]

    test "lists all streaks", %{conn: conn, streak: streak} do
      {:ok, _index_live, html} = live(conn, ~p"/streaks")

      assert html =~ "Listing Streaks"
      assert html =~ streak.name
    end

    test "saves new streak", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/streaks")

      assert index_live |> element("a", "New Streak") |> render_click() =~
               "New Streak"

      assert_patch(index_live, ~p"/streaks/new")

      assert index_live
             |> form("#streak-form", streak: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#streak-form", streak: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/streaks")

      html = render(index_live)
      assert html =~ "Streak created successfully"
      assert html =~ "some name"
    end

    test "updates streak in listing", %{conn: conn, streak: streak} do
      {:ok, index_live, _html} = live(conn, ~p"/streaks")

      assert index_live |> element("#streaks-#{streak.id} a", "Edit") |> render_click() =~
               "Edit Streak"

      assert_patch(index_live, ~p"/streaks/#{streak}/edit")

      assert index_live
             |> form("#streak-form", streak: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#streak-form", streak: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/streaks")

      html = render(index_live)
      assert html =~ "Streak updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes streak in listing", %{conn: conn, streak: streak} do
      {:ok, index_live, _html} = live(conn, ~p"/streaks")

      assert index_live |> element("#streaks-#{streak.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#streaks-#{streak.id}")
    end
  end

  describe "Show" do
    setup [:create_streak]

    test "displays streak", %{conn: conn, streak: streak} do
      {:ok, _show_live, html} = live(conn, ~p"/streaks/#{streak}")

      assert html =~ "Show Streak"
      assert html =~ streak.name
    end

    test "updates streak within modal", %{conn: conn, streak: streak} do
      {:ok, show_live, _html} = live(conn, ~p"/streaks/#{streak}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Streak"

      assert_patch(show_live, ~p"/streaks/#{streak}/show/edit")

      assert show_live
             |> form("#streak-form", streak: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#streak-form", streak: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/streaks/#{streak}")

      html = render(show_live)
      assert html =~ "Streak updated successfully"
      assert html =~ "some updated name"
    end
  end
end
