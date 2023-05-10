defmodule PokerPlanWeb.Pow.Routes do
  use Pow.Phoenix.Routes
  use PokerPlanWeb, :verified_routes

  def after_sign_in_path(_conn), do: ~p"/rounds"
end
