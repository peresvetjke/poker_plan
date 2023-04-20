defmodule PokerPlan.Repo do
  use Ecto.Repo,
    otp_app: :poker_plan,
    adapter: Ecto.Adapters.Postgres
end
