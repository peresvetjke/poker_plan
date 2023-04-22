defmodule PokerPlanWeb.RoundLiveTest do
  use PokerPlanWeb.ConnCase

  import Phoenix.LiveViewTest
  import PokerPlan.RoundsFixtures

  @create_attrs %{title: "some title"}
  @update_attrs %{title: "some updated title"}
  @invalid_attrs %{title: nil}

  defp create_round(_) do
    round = round_fixture()
    %{round: round}
  end

  describe "Index" do
    setup [:create_round]

    test "lists all rounds", %{conn: conn, round: round} do
      {:ok, _index_live, html} = live(conn, ~p"/rounds")

      assert html =~ "Listing Rounds"
      assert html =~ round.title
    end

    test "saves new round", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/rounds")

      assert index_live |> element("a", "New Round") |> render_click() =~
               "New Round"

      assert_patch(index_live, ~p"/rounds/new")

      assert index_live
             |> form("#round-form", round: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#round-form", round: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/rounds")

      html = render(index_live)
      assert html =~ "Round created successfully"
      assert html =~ "some title"
    end

    test "updates round in listing", %{conn: conn, round: round} do
      {:ok, index_live, _html} = live(conn, ~p"/rounds")

      assert index_live |> element("#rounds-#{round.id} a", "Edit") |> render_click() =~
               "Edit Round"

      assert_patch(index_live, ~p"/rounds/#{round}/edit")

      assert index_live
             |> form("#round-form", round: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#round-form", round: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/rounds")

      html = render(index_live)
      assert html =~ "Round updated successfully"
      assert html =~ "some updated title"
    end

    test "deletes round in listing", %{conn: conn, round: round} do
      {:ok, index_live, _html} = live(conn, ~p"/rounds")

      assert index_live |> element("#rounds-#{round.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#rounds-#{round.id}")
    end
  end

  describe "Show" do
    setup [:create_round]

    test "displays round", %{conn: conn, round: round} do
      {:ok, _show_live, html} = live(conn, ~p"/rounds/#{round}")

      assert html =~ "Show Round"
      assert html =~ round.title
    end

    test "updates round within modal", %{conn: conn, round: round} do
      {:ok, show_live, _html} = live(conn, ~p"/rounds/#{round}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Round"

      assert_patch(show_live, ~p"/rounds/#{round}/show/edit")

      assert show_live
             |> form("#round-form", round: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#round-form", round: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/rounds/#{round}")

      html = render(show_live)
      assert html =~ "Round updated successfully"
      assert html =~ "some updated title"
    end
  end
end
