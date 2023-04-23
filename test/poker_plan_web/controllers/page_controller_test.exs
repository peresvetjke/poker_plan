defmodule PokerPlanWeb.PageControllerTest do
  use PokerPlanWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200)
  end
end
