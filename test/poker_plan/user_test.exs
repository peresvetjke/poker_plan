defmodule PokerPlan.UserTest do
  use PokerPlan.DataCase, async: false

  alias PokerPlan.{Repo, User}

  test "base" do
    user = insert_user(%{email: "user@example.com"})

    {:ok, pid} = User.start_link(user)

    assert User.get(pid).email == "user@example.com"
  end
end
